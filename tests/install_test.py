#!/usr/bin/env python3
"""Regression tests for the create-only sample installer."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
INSTALL = ROOT / "install.sh"
SOURCE = ROOT / "SOUL.md"


def run_installer(home: Path, *args: str) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["HOME"] = str(home)
    return subprocess.run(
        ["bash", str(INSTALL), *args],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


def run_fault_injected_installer(
    workspace: Path, mode: str
) -> tuple[subprocess.CompletedProcess[str], Path, Path]:
    fault_root = workspace / f"fault-{mode}"
    fault_root.mkdir(parents=True, exist_ok=True)
    shutil.copy2(INSTALL, fault_root / "install.sh")
    shutil.copy2(SOURCE, fault_root / "SOUL.md")
    wrapper_directory = fault_root / "bin"
    wrapper_directory.mkdir()
    wrapper = wrapper_directory / "python3"
    wrapper.write_text(
        f"#!{sys.executable}\n"
        "import os\n"
        "import sys\n"
        f"mode = {json.dumps(mode)}\n"
        "state = {'published': False, 'injected': False}\n"
        "real_link = os.link\n"
        "def link(*args, **kwargs):\n"
        "    result = real_link(*args, **kwargs)\n"
        "    state['published'] = True\n"
        "    return result\n"
        "os.link = link\n"
        "os.supports_dir_fd = set(os.supports_dir_fd) | {link}\n"
        "os.supports_follow_symlinks = set(os.supports_follow_symlinks) | {link}\n"
        "if mode == 'close':\n"
        "    real_close = os.close\n"
        "    def close(fd):\n"
        "        if state['published'] and not state['injected']:\n"
        "            state['injected'] = True\n"
        "            raise OSError('injected close failure')\n"
        "        return real_close(fd)\n"
        "    os.close = close\n"
        "elif mode == 'unlink':\n"
        "    real_unlink = os.unlink\n"
        "    def unlink(*args, **kwargs):\n"
        "        if state['published'] and not state['injected']:\n"
        "            state['injected'] = True\n"
        "            raise OSError('injected unlink failure')\n"
        "        return real_unlink(*args, **kwargs)\n"
        "    os.unlink = unlink\n"
        "    os.supports_dir_fd = set(os.supports_dir_fd) | {unlink}\n"
        "else:\n"
        "    raise SystemExit(f'unknown fault mode: {mode}')\n"
        "code = sys.stdin.read()\n"
        "sys.argv = sys.argv[1:]\n"
        "namespace = {'__name__': '__main__', '__file__': '<installer-stdin>'}\n"
        "exec(compile(code, '<installer-stdin>', 'exec'), namespace, namespace)\n",
        encoding="utf-8",
    )
    wrapper.chmod(0o755)
    target = fault_root / "sample.md"
    unrelated = fault_root / "unrelated.txt"
    unrelated.write_bytes(b"do not remove")
    env = os.environ.copy()
    env["HOME"] = str(fault_root / "home")
    env["PATH"] = f"{wrapper_directory}{os.pathsep}{env['PATH']}"
    result = subprocess.run(
        ["bash", str(fault_root / "install.sh"), "--target", str(target)],
        cwd=fault_root,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    assert unrelated.read_bytes() == b"do not remove"
    return result, target, fault_root


def snapshot(root: Path) -> dict[str, tuple[object, ...]]:
    result: dict[str, tuple[object, ...]] = {}
    for current, directory_names, file_names in os.walk(root, followlinks=False):
        current_path = Path(current)
        for name in [*directory_names, *file_names]:
            path = current_path / name
            relative = path.relative_to(root).as_posix()
            if path.is_symlink():
                result[relative] = ("symlink", os.readlink(path))
            elif path.is_dir():
                result[relative] = ("directory",)
            else:
                result[relative] = (
                    "file",
                    path.stat().st_mode,
                    path.read_bytes(),
                )
    return result


def assert_rejected(home: Path, tree: Path, *args: str) -> None:
    before = snapshot(tree)
    result = run_installer(home, *args)
    assert result.returncode != 0, (args, result.stdout, result.stderr)
    after = snapshot(tree)
    assert after == before, (args, before, after)


def assert_installed(result: subprocess.CompletedProcess[str], target: Path) -> None:
    assert result.returncode == 0, (result.stdout, result.stderr)
    assert target.is_file() and not target.is_symlink(), target
    assert target.read_bytes() == SOURCE.read_bytes()
    assert stat.S_IMODE(target.stat().st_mode) == 0o644
    expected_digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    match = re.search(r"^sha256: ([0-9a-f]{64})$", result.stdout, re.MULTILINE)
    assert match and match.group(1) == expected_digest, result.stdout


def assert_no_temporary_files(root: Path) -> None:
    leftovers = sorted(root.rglob(".plain-words-gjc.*"))
    assert not leftovers, leftovers


def test_rejects_unsafe_targets(workspace: Path) -> None:
    workspace.mkdir(parents=True, exist_ok=True)
    home = workspace / "home"
    target_root = workspace / "targets"
    target_root.mkdir()

    live_policy_names = (
        "SOUL.md",
        "AGENTS.md",
        "AGENTS.override.md",
        "CLAUDE.md",
        "SYSTEM.md",
        "APPEND_SYSTEM.md",
    )
    for live_policy_name in live_policy_names:
        mixed_case = "".join(
            character.upper() if index % 2 == 0 else character.lower()
            for index, character in enumerate(live_policy_name)
        )
        variants = {
            live_policy_name,
            live_policy_name.lower(),
            live_policy_name.upper(),
            live_policy_name.swapcase(),
            mixed_case,
        }
        for variant in variants:
            for target in (
                target_root / variant,
                target_root / "alias" / ".." / variant,
                target_root / variant / ".." / "safe-sample.md",
            ):
                assert_rejected(home, workspace, "--target", str(target), "--dry-run")
                assert_rejected(
                    home,
                    workspace,
                    "--target",
                    str(target) + "/.",
                    "--dry-run",
                )
    assert_rejected(
        home,
        workspace,
        "--target",
        str(target_root / "new") + "/.",
        "--dry-run",
    )
    assert_rejected(
        home,
        workspace,
        "--target",
        str(target_root / "new") + "/..",
        "--dry-run",
    )
    assert_rejected(
        home,
        workspace,
        "--target",
        str(target_root / "trailing.md") + "/",
        "--dry-run",
    )

    existing = target_root / "existing.md"
    existing.write_bytes(b"keep")
    assert_rejected(home, workspace, "--target", str(existing), "--dry-run")
    assert existing.read_bytes() == b"keep"

    existing_directory = target_root / "existing-directory"
    existing_directory.mkdir()
    assert_rejected(home, workspace, "--target", str(existing_directory), "--dry-run")

    real_target = target_root / "real-target"
    real_target.write_bytes(b"keep")
    symlink_target = target_root / "symlink-target.md"
    symlink_target.symlink_to(real_target)
    assert_rejected(home, workspace, "--target", str(symlink_target), "--dry-run")

    real_parent = target_root / "real-parent"
    real_parent.mkdir()
    symlink_parent = target_root / "symlink-parent"
    symlink_parent.symlink_to(real_parent, target_is_directory=True)
    assert_rejected(
        home,
        workspace,
        "--target",
        str(symlink_parent / "new.md"),
        "--dry-run",
    )

    file_parent = target_root / "file-parent"
    file_parent.write_bytes(b"not a directory")
    assert_rejected(
        home,
        workspace,
        "--target",
        str(file_parent / "new.md"),
        "--dry-run",
    )
    assert_no_temporary_files(workspace)


def test_creates_only_canonical_new_files(workspace: Path) -> None:
    home = workspace / "home"

    default_result = run_installer(home)
    assert_installed(default_result, home / ".hermes" / "SOUL.gjc-sample.md")

    nested_target = workspace / "nested" / "ordinary" / "parents" / "sample.md"
    nested_result = run_installer(home, "--target", str(nested_target))
    assert_installed(nested_result, nested_target)

    dry_target = workspace / "dry-run" / "missing" / "sample.md"
    dry_result = run_installer(home, "--target", str(dry_target), "--dry-run")
    canonical_dry_target = Path(os.path.realpath(dry_target))
    assert dry_result.returncode == 0, (dry_result.stdout, dry_result.stderr)
    assert f"would create: {canonical_dry_target}" in dry_result.stdout
    assert not dry_target.parent.exists()

    alias_target = workspace / "ordinary" / ".." / "safe-alias.md"
    alias_result = run_installer(home, "--target", str(alias_target))
    canonical_alias_target = Path(os.path.realpath(alias_target))
    assert_installed(alias_result, canonical_alias_target)
    assert not (workspace / "ordinary").exists()

    existing_target = workspace / "existing-after-preview.md"
    existing_target.write_bytes(b"original")
    rejected = run_installer(home, "--target", str(existing_target))
    assert rejected.returncode != 0, (rejected.stdout, rejected.stderr)
    assert existing_target.read_bytes() == b"original"
    assert_no_temporary_files(workspace)


def test_post_publication_cleanup_faults(workspace: Path) -> None:
    for mode in ("close", "unlink"):
        result, target, fault_root = run_fault_injected_installer(workspace, mode)
        assert_installed(result, target)
        assert "warning:" in result.stderr, result.stderr
        assert "after publication" in result.stderr, result.stderr
        leftovers = list(fault_root.rglob(".plain-words-gjc.*"))
        if mode == "close":
            assert not leftovers, leftovers
        else:
            assert len(leftovers) == 1, leftovers
            assert leftovers[0] != target


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="plain-words-installer-test-") as directory:
        workspace = Path(directory)
        test_rejects_unsafe_targets(workspace / "negative")
        test_creates_only_canonical_new_files(workspace / "positive")
        test_post_publication_cleanup_faults(workspace / "faults")
    print("installer tests: PASS")


if __name__ == "__main__":
    main()

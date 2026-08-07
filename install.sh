#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [--target PATH] [--dry-run]

Install the sample as a new file. Existing targets, live-policy-equivalent path
components (these six ASCII names and their case-equivalent spellings:
SOUL.md, AGENTS.md, AGENTS.override.md, CLAUDE.md, SYSTEM.md, and
APPEND_SYSTEM.md), final symlinks, and symlinked parents are refused. On
supported POSIX systems, missing parents are created and publication uses
no-follow directory descriptors; dry-run does not reserve the target and
privileged filesystem races remain out of scope. Cleanup errors after
publication warn and may leave an owned temporary.
The default target is ~/.hermes/SOUL.gjc-sample.md; it does not replace
~/.hermes/SOUL.md.
EOF
}

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source_file="$root_dir/SOUL.md"
target="${HOME}/.hermes/SOUL.gjc-sample.md"
dry_run=0

while (($#)); do
  case "$1" in
    --target)
      if (($# < 2)); then
        echo "--target needs a path" >&2
        exit 2
      fi
      target="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for safe hashing and create-only publication" >&2
  exit 1
fi

exec python3 - "$source_file" "$target" "$dry_run" <<'PY'
from __future__ import annotations

import hashlib
import os
import stat
import sys
import secrets


class InstallerError(Exception):
    """A fail-closed installer validation or publication error."""


O_CLOEXEC = getattr(os, "O_CLOEXEC", 0)
O_DIRECTORY = getattr(os, "O_DIRECTORY", None)
O_NOFOLLOW = getattr(os, "O_NOFOLLOW", None)
LIVE_POLICY_COMPONENTS = frozenset(
    {
        "SOUL.md",
        "AGENTS.md",
        "AGENTS.override.md",
        "CLAUDE.md",
        "SYSTEM.md",
        "APPEND_SYSTEM.md",
    }
)
LIVE_POLICY_COMPONENTS_CASEFOLDED = frozenset(
    component.casefold() for component in LIVE_POLICY_COMPONENTS
)


def fail(message: str) -> None:
    raise InstallerError(message)


def reject_live_policy_components(parts: list[str]) -> None:
    # Some POSIX filesystems are case-insensitive. Reject equivalent spellings
    # so an inactive sample can never resolve to a reserved live surface.
    if any(part.casefold() in LIVE_POLICY_COMPONENTS_CASEFOLDED for part in parts):
        fail("live-policy target paths are not allowed")


def require_safe_posix_support() -> None:
    if os.name != "posix" or O_DIRECTORY is None or O_NOFOLLOW is None:
        fail("this installer requires POSIX O_DIRECTORY and O_NOFOLLOW support")
    required_dir_fd = (os.open, os.mkdir, os.stat, os.unlink, os.link)
    if not all(function in os.supports_dir_fd for function in required_dir_fd):
        fail("this platform lacks the required directory-descriptor operations")
    if os.link not in os.supports_follow_symlinks:
        fail("this platform cannot publish with link no-follow semantics")


def lexical_entries(path: str):
    current = os.path.sep
    for component in path.split(os.path.sep):
        if component in ("", "."):
            continue
        if component == "..":
            current = os.path.dirname(current.rstrip(os.path.sep)) or os.path.sep
            continue
        current = os.path.join(current, component)
        yield current, component


def lstat_or_missing(path: str):
    try:
        return os.lstat(path)
    except FileNotFoundError:
        return None
    except OSError as exc:
        fail(f"cannot inspect target path {path}: {exc}")


def reject_existing_symlinks(path: str) -> None:
    for component_path, _ in lexical_entries(path):
        metadata = lstat_or_missing(component_path)
        if metadata is not None and stat.S_ISLNK(metadata.st_mode):
            fail(f"target passes through an existing symlink: {component_path}")


def validate_target(requested: str) -> tuple[str, str, str]:
    raw = os.path.expanduser(requested)
    if not os.path.isabs(raw):
        raw = os.path.join(os.getcwd(), raw)

    raw_parts = [part for part in raw.split(os.path.sep) if part]
    if not raw_parts:
        fail("target must name a new file leaf")
    if raw.endswith(os.path.sep):
        fail("target must not use a trailing slash")
    if raw_parts[-1] in (".", ".."):
        fail("target must end with a file name, not . or ..")
    reject_live_policy_components(raw_parts)

    reject_existing_symlinks(raw)
    # Existing symlinks are forbidden, so lexical normalization is the safe
    # canonical identity. It avoids following a symlink inserted between this
    # preflight and the descriptor-relative traversal below.
    canonical = os.path.normpath(raw)
    canonical_parts = [part for part in canonical.split(os.path.sep) if part]
    if not canonical_parts:
        fail("live-policy target paths are not allowed")
    reject_live_policy_components(canonical_parts)
    if os.path.basename(canonical) in ("", ".", ".."):
        fail("target must name a new file leaf")

    # Re-check the resolved spelling. A concurrent rename can otherwise make
    # the path used for publication differ from the path that was inspected.
    reject_existing_symlinks(canonical)
    existing = lstat_or_missing(canonical)
    if existing is not None:
        fail(f"refusing to overwrite existing target: {canonical}")

    parent = os.path.dirname(canonical)
    for component_path, _ in lexical_entries(parent):
        metadata = lstat_or_missing(component_path)
        if metadata is not None:
            if stat.S_ISLNK(metadata.st_mode):
                fail(f"target parent is a symlink: {component_path}")
            if not stat.S_ISDIR(metadata.st_mode):
                fail(f"target parent is not a directory: {component_path}")

    return canonical, parent, os.path.basename(canonical)


def open_source(path: str) -> int:
    flags = os.O_RDONLY | O_CLOEXEC | O_NOFOLLOW
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        fail(f"sample source is missing, inaccessible, or a symlink: {path}: {exc}")
    metadata = os.fstat(descriptor)
    if not stat.S_ISREG(metadata.st_mode):
        os.close(descriptor)
        fail(f"sample source is not a regular file: {path}")
    return descriptor


def directory_flags() -> int:
    return os.O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW


def open_or_create_child(parent_fd: int, name: str) -> int:
    try:
        return os.open(name, directory_flags(), dir_fd=parent_fd)
    except FileNotFoundError:
        try:
            os.mkdir(name, 0o755, dir_fd=parent_fd)
        except FileExistsError:
            pass
        try:
            return os.open(name, directory_flags(), dir_fd=parent_fd)
        except OSError as exc:
            fail(f"target parent component is unsafe: {name}: {exc}")
    except OSError as exc:
        fail(f"target parent component is unsafe: {name}: {exc}")


def open_parent_directory(canonical_parent: str) -> int:
    descriptor = os.open(os.path.sep, directory_flags())
    try:
        components = [part for part in canonical_parent.split(os.path.sep) if part]
        for component in components:
            child = open_or_create_child(descriptor, component)
            os.close(descriptor)
            descriptor = child
        return descriptor
    except Exception:
        os.close(descriptor)
        raise


def write_all(descriptor: int, data: bytes) -> None:
    view = memoryview(data)
    while view:
        written = os.write(descriptor, view)
        if written <= 0:
            fail("could not write the sample temporary file")
        view = view[written:]


def create_temporary(parent_fd: int) -> tuple[int, str]:
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | O_CLOEXEC | O_NOFOLLOW
    for _ in range(32):
        name = f".plain-words-gjc.{os.getpid()}.{secrets.token_hex(8)}"
        try:
            return os.open(name, flags, 0o600, dir_fd=parent_fd), name
        except FileExistsError:
            continue
        except OSError as exc:
            fail(f"could not create a temporary file in the target directory: {exc}")
    fail("could not choose a unique temporary file name")


def warn(message: str) -> None:
    try:
        print(f"warning: {message}", file=sys.stderr)
    except OSError:
        pass


def close_quietly(descriptor: int, label: str) -> None:
    try:
        os.close(descriptor)
    except OSError as exc:
        warn(f"could not close {label}: {exc}")


def verify_temporary(parent_fd: int, name: str, descriptor: int):
    metadata = os.fstat(descriptor)
    if not stat.S_ISREG(metadata.st_mode):
        fail("installer temporary is not a regular file")
    try:
        entry = os.stat(name, dir_fd=parent_fd, follow_symlinks=False)
    except FileNotFoundError:
        fail("installer temporary disappeared before publication")
    except OSError as exc:
        fail(f"could not verify installer temporary before publication: {exc}")
    if not stat.S_ISREG(entry.st_mode) or (entry.st_dev, entry.st_ino) != (
        metadata.st_dev,
        metadata.st_ino,
    ):
        fail("installer temporary identity changed before publication")
    return metadata


def reject_existing_target(parent_fd: int, name: str) -> None:
    try:
        os.stat(name, dir_fd=parent_fd, follow_symlinks=False)
    except FileNotFoundError:
        return
    except OSError as exc:
        fail(f"could not recheck target before publication: {exc}")
    fail(f"refusing to overwrite existing target: {name}")


def remove_owned_temporary(
    parent_fd: int, name: str, metadata, published: bool
) -> None:
    if metadata is None:
        return
    phase = "after publication" if published else "before publication"
    try:
        current = os.stat(name, dir_fd=parent_fd, follow_symlinks=False)
    except FileNotFoundError:
        return
    except OSError as exc:
        warn(f"could not inspect installer temporary {name} {phase}; leaving it in place: {exc}")
        return
    if (current.st_dev, current.st_ino) != (metadata.st_dev, metadata.st_ino):
        warn(f"installer temporary {name} changed {phase}; leaving it in place")
        return
    try:
        os.unlink(name, dir_fd=parent_fd)
    except FileNotFoundError:
        pass
    except OSError as exc:
        warn(f"could not remove installer temporary {name} {phase}; leaving it in place: {exc}")


def publish(source_fd: int, parent_fd: int, target_name: str) -> str:
    temporary_fd, temporary_name = create_temporary(parent_fd)
    temporary_metadata = None
    published = False
    try:
        temporary_metadata = os.fstat(temporary_fd)
        digest = hashlib.sha256()
        while True:
            block = os.read(source_fd, 1024 * 1024)
            if not block:
                break
            digest.update(block)
            write_all(temporary_fd, block)
        os.fchmod(temporary_fd, 0o644)
        os.fsync(temporary_fd)
        published_digest = digest.hexdigest()
        temporary_metadata = verify_temporary(parent_fd, temporary_name, temporary_fd)
        reject_existing_target(parent_fd, target_name)

        # This create-only link is the publication point. Every fallible
        # validation and identity check must finish before it succeeds.
        try:
            os.link(
                temporary_name,
                target_name,
                src_dir_fd=parent_fd,
                dst_dir_fd=parent_fd,
                follow_symlinks=False,
            )
        except FileExistsError:
            fail(f"target appeared or could not be created without overwrite: {target_name}")
        except OSError as exc:
            fail(f"could not publish the sample without overwrite: {exc}")
        published = True
        return published_digest
    finally:
        # Cleanup is independent: after publication it may warn, but it must
        # never remove the target or turn a successful install into a failure.
        cleanup_phase = " after publication" if published else ""
        close_quietly(temporary_fd, f"installer temporary{cleanup_phase}")
        remove_owned_temporary(parent_fd, temporary_name, temporary_metadata, published)


def main() -> int:
    source_path, requested_target, dry_run_text = sys.argv[1:]
    dry_run = dry_run_text == "1"
    require_safe_posix_support()
    canonical, parent, target_name = validate_target(requested_target)
    source_fd = open_source(source_path)
    try:
        if dry_run:
            print(f"would create: {canonical}")
            print(f"from: {source_path}")
            return 0

        parent_fd = open_parent_directory(parent)
        try:
            digest = publish(source_fd, parent_fd, target_name)
        finally:
            close_quietly(parent_fd, "target parent directory")
    finally:
        close_quietly(source_fd, "sample source")

    try:
        print(f"installed: {canonical}")
        print(f"sha256: {digest}")
        print("note: this adjacent sample is not automatically loaded as ~/.hermes/SOUL.md")
    except OSError as exc:
        warn(f"sample installed, but status output was incomplete: {exc}")
    return 0


try:
    raise SystemExit(main())
except InstallerError as error:
    print(f"installer refused: {error}", file=sys.stderr)
    raise SystemExit(1)
PY

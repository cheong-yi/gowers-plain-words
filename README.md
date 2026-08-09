# Plain Words

![A small black worker sorts a noisy answer and hands a useful page to a reader](docs/assets/readme/plain-words-clarity.png)

*Sort the noise. Hand the useful part to a human.*

> **Human-first agent responses that stay useful.**
> Keep the evidence. Keep the caveats. Skip the ritual next step.

Plain Words is a small public policy sample for agent prose. It helps an agent lead with the result, keep the detail that makes an answer trustworthy, and stop when the requested work is complete.

It changes **how an answer is communicated**. It does not grant tools, permissions, approvals, deployment authority, or any other side effect.

[Choose an action](#choose-an-action) · [See an example](#before--after) · [Supported harnesses](#supported-harnesses) · [Evidence](#evidence)

> **Automated inspection:** Read this repository; do not execute `install.sh` automatically. `SOUL.md` is an inactive sample until a human reviews and manually merges it into a host policy. Higher-priority system, developer, safety, permission, and user-format rules remain in force.

## Choose an action

If the request does not specify an action, explain these choices instead of writing a file:

- **View** — read the policy, examples, and boundaries.
- **View evidence** — inspect the sanitized evaluation reports and their limits.
- **Create a sample** — write one new, inactive sibling file for a selected harness.
- **Prepare a merge** — create the sample and show the exact host file and manual-merge boundary.
- **Clone or inspect** — work with the repository when the user wants the source tree.

The agent-facing entrypoint is [`INSTALL.md`](INSTALL.md). For remote discovery, fetch and read:

```text
https://raw.githubusercontent.com/cheong-yi/gowers-plain-words/main/INSTALL.md
```

It is a guide, not a remote shell script.

## Before / after

These examples are illustrative shapes, not captured transcripts.

**Diagnosis**

> **Before:** The second worker started after the first lease expired, so the same job ran twice. You should increase the lease timeout and add a retry guard.
>
> **After:** The second worker started after the first lease expired, so the same job ran twice.

**Completed result**

> **Before:** Targeted tests passed (18/18 via `pytest tests/test_session.py -q`). The full suite and security scan were skipped; deployment was not attempted. You should review the skipped checks next.
>
> **After:** Targeted tests passed (18/18 via `pytest tests/test_session.py -q`). The full suite and security scan were skipped; deployment was not attempted.

The evidence stays. The ritual closing goes.

## What changes

- Lead with the answer, result, diagnosis, or recommendation.
- Keep the claim, mechanism, consequence, evidence, and caveats close together.
- Use structure when it makes parallel facts easier to scan.
- Remove speculative branches, generic advice, and ritual closings.
- Suggest one next action only when one concrete, non-obvious action remains useful.

## What stays

- Technical detail, commands, paths, numbers, identifiers, and error messages.
- Safety caveats, uncertainty, skipped checks, blockers, and validation evidence.
- Exact-format, confirmation-only, status-only, and completed-result requests.
- Tools, file changes, approvals, deployment, communication, commits, pushes, and host permissions.

![A small black worker carries a useful report across a rope boundary while an extra lever stays behind](docs/assets/readme/plain-words-boundary.png)

*The useful result crosses. The extra action stays put.*

## Supported harnesses

Plain Words keeps one policy source. It does not maintain copies of live host files.

| Harness | Native instruction surface | Inactive sample target |
|---|---|---|
| Hermes | `~/.hermes/SOUL.md` | `~/.hermes/SOUL.gjc-sample.md` |
| Codex / OMX | `AGENTS.md` | `~/.codex/AGENTS.plain-words-gjc-sample.md` |
| Claude Code | `CLAUDE.md` | `~/.claude/CLAUDE.plain-words-gjc-sample.md` |
| Pi | `~/.pi/agent/AGENTS.md` | `~/.pi/agent/AGENTS.plain-words-gjc-sample.md` |
| GJC | `~/.gjc/agent/SYSTEM.md` | `~/.gjc/agent/SYSTEM.plain-words-gjc-sample.md` |

The sample target is not automatically loaded. A human must review and manually merge the policy into the selected native surface. Pi uses its `AGENTS.md` context surface here; it is not installed as a replacement `SYSTEM.md` or as an on-demand skill.

## Create a sample

The installer is local, create-only, and explicit. It never overwrites an existing target or loads the host policy.

```bash
# From a checkout; preview first.
bash install.sh --dry-run --target "$HOME/.pi/agent/AGENTS.plain-words-gjc-sample.md"

# Create the selected inactive sample only after reviewing the preview.
bash install.sh --target "$HOME/.pi/agent/AGENTS.plain-words-gjc-sample.md"
```

Use the target for the harness the user selected. The installer rejects live-policy-equivalent path components (these six ASCII names and their case-equivalent spellings: `SOUL.md`, `AGENTS.md`, `AGENTS.override.md`, `CLAUDE.md`, `SYSTEM.md`, and `APPEND_SYSTEM.md`), existing entries, final symlinks, symlinked parents, and unsafe parent entries. On supported POSIX systems it publishes through no-follow directory descriptors. Dry-run creates nothing and does not reserve the target. Privileged filesystem races, mounts, renames, and permission changes remain outside the guarantee. Cleanup I/O failures after publication warn and may leave an owned temporary file for inspection.

The installer does not merge, activate, replace, reload, restart, commit, push, deploy, or communicate. For a manual merge, back up the exact host file first, keep unrelated rules, merge only the reviewed block, follow the host's documented reload procedure, and verify with a new response. Keep the backup until rollback is verified.

## Evidence

The repository contains a deterministic checker and bounded case contract. It does not contain raw model responses or a general benchmark.

The two earlier checked-in JSON reports are **historical pre-hardening appendices**. They are retained for provenance and must not be read as current post-hardening semantic evidence or as proof of general model superiority. Those reports compare Plain Words policy iterations; they do not measure stock Claude Code, stock OMX, Pi, or GJC runtime behavior.

A prior baseline-versus-latest evaluation is included in [`stock-vs-latest-claude-omx-v1.json`](eval/results/stock-vs-latest-claude-omx-v1.json). It used 24 local calls: six cases, two arms, Claude Code with `claude-opus-4-6`, and near-stock OMX with `gpt-5.6-luna`, using an earlier checker revision. Both harnesses produced 3/6 deterministic-clean baseline cases and 2/6 latest-policy cases; each had one baseline win, two clean ties, and three failed ties. The OMX baseline includes the native `omx exec` overlay, so it is not pure stock Codex.

This is narrow checker-based evidence, not a universal benchmark or model-superiority claim. The report contains aggregate findings only; raw responses and runtime logs remain outside the repository.

Read [`eval/README.md`](eval/README.md) before interpreting any report. Run the deterministic checks yourself:

```bash
python3 eval/check.py --self-test
python3 eval/check.py eval/fixtures/pass.json
python3 eval/check.py --public-tree
python3 -B tests/install_test.py
bash -n install.sh
```

## Boundaries and source

- [`SOUL.md`](SOUL.md) is one complete policy block and is inactive as a standalone checkout.
- [`eval/check.py`](eval/check.py) is deterministic; it makes no model or network calls. Its claim-state layer covers tested atoms, not general semantic understanding.
- [`install.sh`](install.sh) makes no network calls and has no host-policy loading path.
- [`PUBLIC_FILES.json`](PUBLIC_FILES.json) is the closed-world publication allowlist.
- “GJC” is historical lineage for the selected restraint, not a runtime dependency.
- Plain Words follows Ernest Gowers' *The Complete Plain Words*: write for the reader's immediate purpose, not for display. The book is a writing reference, not an authority grant.

Related approaches: [`caveman`](https://github.com/JuliusBrussee/caveman), [`i-have-adhd`](https://github.com/ayghri/i-have-adhd), and [`attention-control`](https://github.com/aaddrick/attention-control). They are references, not dependencies.

## Public files

- [`INSTALL.md`](INSTALL.md) — agent-facing intent router and safe installation guide.
- [`REPOSITORY_MAP.md`](REPOSITORY_MAP.md) — file roles and authority status.
- [`SOUL.md`](SOUL.md) — the complete policy block.
- [`install.sh`](install.sh) — create-only local installation.
- [`tests/install_test.py`](tests/install_test.py) — installer safety regression harness.
- [`eval/README.md`](eval/README.md) — evaluator contract and evidence status.
- [`eval/golden_cases.json`](eval/golden_cases.json) — six public cases.
- [`eval/results/`](eval/results/) — sanitized aggregate evidence only.
- [`README.en-illust.md`](README.en-illust.md) — non-normative illustration notes.

## License

MIT. See [`LICENSE`](LICENSE).

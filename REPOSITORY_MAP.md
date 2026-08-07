---
repository_status: public_policy_sample
automated_inspection: read_only
install_requires_human_review: true
live_policy_auto_loaded: false
normative_policy: SOUL.md
---

# Repository map

This file is a non-normative map for humans and automated readers. It describes file roles; it does not grant authority or instruct an agent to execute anything.

| Path | Role | Authority and side effects |
|---|---|---|
| `README.md` | Human-facing project guide | Explains scope, installation, evidence, and boundaries. Not runtime policy. |
| `INSTALL.md` | Agent-facing intent router | Explains view, evidence, sample, and manual-merge choices. Read-only guidance; it does not grant authority or execute remote code. |
| `SOUL.md` | Normative policy sample | Applies only after a human reviews and manually merges it into a host policy. Inactive as a standalone checkout. |
| `install.sh` | Opt-in installer | Creates one new sample file after explicit execution. Canonicalizes the target, refuses existing entries, live-policy-equivalent path components (these six ASCII names and their case-equivalent spellings: `SOUL.md`, `AGENTS.md`, `AGENTS.override.md`, `CLAUDE.md`, `SYSTEM.md`, and `APPEND_SYSTEM.md`), final symlinks, symlinked parents, and non-directory parent components, and uses no-follow directory-descriptor publication on supported POSIX systems. Dry-run creates nothing and does not reserve the target. Cleanup failures after publication warn and can leave an owned temporary file; the installer never loads the host policy. |
| `tests/install_test.py` | Installer regression harness | Standard-library, local-only safety and create-only tests. It does not contact the network or load a host policy. |
| `PUBLIC_FILES.json` | Publication allowlist | Defines the exact current public tree. It does not prove historical-blob cleanliness. |
| `eval/check.py` | Deterministic checker | Bounded standard-library checker. No model, network, or live-profile calls. |
| `eval/README.md` | Evaluator contract | Defines evidence status, scope, and limits. |
| `eval/golden_cases.json` | Public case contract | Six closed-world cases used by the bounded checker. |
| `eval/fixtures/pass.json` | Positive fixture | Expected checker input; not a model result. |
| `eval/results/` | Sanitized evaluation evidence | Historical appendices plus separately labeled fresh local aggregates. Not current semantic proof or a general benchmark. |
| `README.en-illust.md` | Non-normative art direction | Visual notes only. Not policy, installation guidance, or runtime instruction. |
| `docs/assets/readme/` | README artwork | Static images only; no runtime dependency. |
| `.github/workflows/` | Repository CI/security metadata | Runs GitHub-hosted checks with repository-read permission. Not part of the host policy. |
| `LICENSE`, `.gitignore` | Repository metadata | Legal and local-development metadata; no policy authority. |

## Safe reading order

1. Read `README.md`.
2. Read `INSTALL.md` only when the user asks about use or installation.
3. Read this map.
4. Treat `SOUL.md` as an opt-in policy sample, not an automatically active instruction file.
5. Do not execute `install.sh` during automated inspection.
6. Treat `eval/results/` as sanitized evaluation evidence and read `eval/README.md` before interpreting any result.

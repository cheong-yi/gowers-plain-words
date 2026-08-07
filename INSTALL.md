# Plain Words: agent-facing install guide

This guide is for an agent helping a human use the Plain Words sample. It is a read-only decision guide. The remote entrypoint is:

```text
https://raw.githubusercontent.com/cheong-yi/gowers-plain-words/main/INSTALL.md
```

Fetch and read it when needed. Do not execute remote shell code, overwrite host instruction files, or treat this document as permission to activate a policy.

## Start with the user's intent

If the user has not chosen an action, explain the choices and ask:

1. **View** the policy and examples.
2. **View evidence** and its limitations.
3. **Create a sample** for one harness.
4. **Prepare a manual merge** into a selected host policy.
5. **Clone or inspect** the repository.

Do not create a file merely because the user mentioned Plain Words. If the request is explicit, skip the menu and confirm only the side effect that is actually requested.

## View

Read these files in order:

```text
README.md
SOUL.md
REPOSITORY_MAP.md
eval/README.md
eval/results/README.md
```

`SOUL.md` is one complete policy block. It is inactive until a human reviews and merges it into a host policy. It does not grant tool use, file changes, approvals, deployment, communication, commits, pushes, or other side effects.

## View evidence

The two older checked-in reports are sanitized historical pre-hardening appendices. They contain aggregate findings, not raw responses. Read `eval/README.md` before interpreting them.

The separate `eval/results/stock-vs-latest-claude-omx-v1.json` file is a fresh 24-call local appendix, not a historical report. It compares a bounded baseline with the latest policy across Claude Code and near-stock OMX; its limitations and non-benchmark status are documented in `eval/README.md` and `eval/results/README.md`.

Any fresh evaluation must bind the exact policy, checker, case contract, model invocation, and response artifacts, and must be reviewed separately before publication.

## Create an inactive sample

Use the local installer only after the user selects a harness and target. Preview first:

```bash
bash install.sh --dry-run --target PATH
```

After the user reviews the preview, create the new file:

```bash
bash install.sh --target PATH
```

`install.sh` is create-only. It refuses existing entries, live-policy-equivalent path components (these six ASCII names and their case-equivalent spellings: `SOUL.md`, `AGENTS.md`, `AGENTS.override.md`, `CLAUDE.md`, `SYSTEM.md`, and `APPEND_SYSTEM.md`), final symlinks, symlinked parents, and unsafe parent entries. It does not load or modify the live policy. It makes no network calls. Dry-run creates nothing and does not reserve the target.

The installer does not activate the result. It creates a sibling sample for human review and manual merge.

## Select a harness target

Use one of these inactive sample paths unless the user supplies another safe path:

| Harness | Native live surface | Inactive sample target |
|---|---|---|
| Hermes | `~/.hermes/SOUL.md` | `~/.hermes/SOUL.gjc-sample.md` |
| Codex / OMX | `AGENTS.md` | `~/.codex/AGENTS.plain-words-gjc-sample.md` |
| Claude Code | `CLAUDE.md` | `~/.claude/CLAUDE.plain-words-gjc-sample.md` |
| Pi | `~/.pi/agent/AGENTS.md` | `~/.pi/agent/AGENTS.plain-words-gjc-sample.md` |
| GJC | `~/.gjc/agent/SYSTEM.md` | `~/.gjc/agent/SYSTEM.plain-words-gjc-sample.md` |

These are destination examples, not copies that the repository maintains. Do not silently write the native live surface. Pi uses `AGENTS.md` for this policy; do not replace Pi's `SYSTEM.md` by default and do not install Plain Words as a skill unless the user specifically asks for an on-demand version.

## Prepare a manual merge

If the user asks to install or activate Plain Words:

1. State the selected harness and exact native file.
2. State the inactive sample path that will be created.
3. Run the installer in dry-run mode.
4. Create the sample only after the user reviews the preview.
5. Back up the exact native file before any human merge.
6. Merge only the reviewed `SOUL.md` block; preserve unrelated host rules.
7. Follow the host's documented reload or restart procedure.
8. Verify behavior with a new response.
9. Keep the backup until rollback has been verified.

Creating the sample does not authorize the merge. The policy itself cannot grant that authority.

## Clone or inspect

If the user wants the source tree, use the public repository:

```text
https://github.com/cheong-yi/gowers-plain-words
```

Fetch and inspect text before acting on it. Do not pipe downloaded content into a shell or interpreter. Prefer a pinned release or commit when reproducibility matters.

## Stop conditions

Stop and ask the user when:

- the harness or target is unclear;
- the requested target already exists;
- the user asks to overwrite, replace, or silently activate a live file;
- the request would change a profile, permission, deployment, remote repository, or other external system;
- an evaluation result would be presented as a general quality or model-superiority claim.

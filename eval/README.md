---
evidence_status: mixed_historical_and_fresh_local
not_current_semantic_evidence: true
model_evaluation_replayable_from_tree: false
baseline_policy_available: false
raw_model_responses_available: false
checker_scope: bounded_closed_world_cases
live_policy_mutation_authorized: false
fresh_local_report: results/stock-vs-latest-claude-omx-v1.json
---

# Evaluator contract

This directory contains a bounded deterministic checker and public case contracts. It is not a model runner and it does not establish general semantic understanding, live Hermes integration, or universal response quality.

## Checks

```bash
python3 -B eval/check.py --self-test
python3 -B eval/check.py eval/fixtures/pass.json
python3 -B eval/check.py --public-tree
```

`--self-test` checks the checker and its fail-closed fixtures. `--public-tree` checks the exact `PUBLIC_FILES.json` allowlist and expects a clean public tree. Passing these commands is not evidence that a model follows the policy in arbitrary contexts.

## Evidence status

The older JSON files under [`results/`](results/) are immutable historical pre-hardening appendices. Their counts and hashes are provenance, not current post-hardening semantic evidence. The public tree does not contain their compared baseline policy, raw model responses, prompts, runtime logs, or off-repository evaluator artifacts, so those reports cannot be replayed from this repository alone.

[`stock-vs-latest-claude-omx-v1.json`](results/stock-vs-latest-claude-omx-v1.json) is a prior 24-call local appendix generated with an earlier checker revision, not current post-v2 semantic evidence. It used six cases, Claude Code with `claude-opus-4-6`, and near-stock OMX with `gpt-5.6-luna`, comparing a bounded baseline with the then-latest `SOUL.md` policy. Both harnesses produced 3/6 deterministic-clean baseline cases and 2/6 latest-policy cases; each had one baseline win, two clean ties, and three failed ties. OMX's baseline includes the native `omx exec` overlay, so it is not a pure stock Codex run. This narrow result does not establish that the baseline or policy is generally better.

This appendix binds the exact policy, checker, case contract, and model invocation from its run. It contains aggregate findings only; raw responses and runtime logs remain outside the repository. It must not be used as a general benchmark or universal response-quality claim.

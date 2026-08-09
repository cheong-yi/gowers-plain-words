# Sanitized evaluation results

This directory contains small public evidence appendices for the Plain Words sample. They are aggregate exports, not transcript archives.

## Included

The JSON reports record:

- the bounded harness, model family, reasoning effort, policies, and case IDs;
- policy, case, and checker SHA-256 values;
- process and checker-error counts;
- case-level clean/fail status and deterministic finding categories;
- pairwise totals and explicit limitations.

## Reports

- [`omx-luna-xhigh-calibration-v1.json`](omx-luna-xhigh-calibration-v1.json) — six-call targeted OMX/Luna calibration appendix; historical pre-hardening checker output.
- [`claude-opus-4-6-targeted-v1.json`](claude-opus-4-6-targeted-v1.json) — 12-call Claude-only matrix across six cases and two policies; historical pre-hardening checker output.
- [`stock-vs-latest-claude-omx-v1.json`](stock-vs-latest-claude-omx-v1.json) — fresh 24-call local appendix comparing a bounded baseline with the exact latest policy across Claude Code and near-stock OMX.

The two earlier reports are immutable provenance appendices from earlier checker versions. The current checker has since received a bounded claim-state hardening pass for causal polarity, decision subject binding, approval directives, unknown-state closure, and bounded speech-act handling. Their recorded counts and hashes are not post-hardening results and should not be read as current semantic proof.

The prior appendix is separate from those historical reports. It records 3/6 deterministic-clean baseline cases and 2/6 latest-policy cases for both harnesses. The OMX baseline includes its native `omx exec` overlay, so it is near-stock rather than pure stock Codex. The result is narrow local evidence, not a universal benchmark or model-superiority claim.

The appendix was generated with an earlier checker revision, SHA-256 `4f3779e77a36066410ebe600716341021c2e1f62417aeb742beeb66855d92659`. The current `eval/check.py` has SHA-256 `b2b331d50550aa3c4a339cacd71f0f2a6b7250ab0cca49b38386bd9a4bcdf272`; the appendix is retained as prior local evidence, not a current post-v2 result.

## Deliberately excluded

The exports contain no model response text, prompt copies, transcripts, session IDs, Discord or Telegram identifiers, absolute paths, cache paths, provider credentials, tokens, costs, or runtime logs. Raw evaluator directories remain outside the repository.

The exports were reviewed field by field and checked with bounded pattern scans for session identifiers, private paths, credentials, tokens, email addresses, and other PII. Gitleaks remains a separate repository gate; it is not the anonymisation method.

---
description: Structured diff-based review against specified or base branch (/code-review [targetBranch])
agent: code-reviewer
---
Collecting diff vs target branch...

!`ARG="$ARGUMENTS"; DEFAULT=$(git remote show origin 2>/dev/null | awk -F': ' '/HEAD branch/ {print $2}' | head -n1); [ -z "$DEFAULT" ] && { [ -d .git/refs/heads/main ] && DEFAULT=main || DEFAULT=master; }; TARGET=""; if [ -n "$ARG" ] && [ "$ARG" != "\$ARGUMENTS" ]; then if git show-ref --verify --quiet "refs/heads/$ARG" || git ls-remote --exit-code origin "$ARG" >/dev/null 2>&1; then TARGET="$ARG"; else echo "[info] Branch '$ARG' not found locally/remotely, falling back to default ($DEFAULT)." >&2; fi; fi; [ -z "$TARGET" ] && TARGET="$DEFAULT"; git fetch origin "$TARGET" --quiet 2>/dev/null || true; echo "=== Diff Mode: comparing HEAD against: $TARGET ==="; git diff "$TARGET"...HEAD || echo "[warn] Diff failed for $TARGET...HEAD"`

INSTRUCTIONS (Diff Review Mode):
Provide output in the exact required structure defined in the agent prompt (Executive Summary, Severity Table, Detailed Findings, Positive Notes, Prioritized Remediation Plan, Optional Docs). Assume DIFF MODE unless told otherwise.

Scope Discipline:
- Focus ONLY on changed lines + minimal necessary surrounding context.
- Avoid speculative whole-architecture critiques unless the diff clearly intersects systemic boundaries.
- Group minor style nits; do not list each individually.

Library Docs Usage:
- If unfamiliar or third-party APIs appear, and context7 tools available, selectively fetch minimal documentation (specific symbol) BEFORE finalizing the relevant finding. Cite briefly: (Docs: <library> <symbol>). If resolution fails, note uncertainty.

If the diff is empty: State that no changes are detected; still produce Executive Summary (no issues) + Positive Notes if any.

Return only the structured review. Do not add conversational preamble or extra sections.

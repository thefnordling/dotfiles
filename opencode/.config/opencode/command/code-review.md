---
description: Review current branch changes against specified or base branch (uses context7 docs when helpful)
agent: code-reviewer
---
Reviewing changes against target branch...

!`ARG="$ARGUMENTS"; DEFAULT=$(git remote show origin 2>/dev/null | awk -F': ' '/HEAD branch/ {print $2}' | head -n1); [ -z "$DEFAULT" ] && { [ -d .git/refs/heads/main ] && DEFAULT=main || DEFAULT=master; }; TARGET=""; if [ -n "$ARG" ] && [ "$ARG" != "\$ARGUMENTS" ]; then if git show-ref --verify --quiet "refs/heads/$ARG" || git ls-remote --exit-code origin "$ARG" >/dev/null 2>&1; then TARGET="$ARG"; else echo "[info] Branch '$ARG' not found locally/remotely, falling back to default ($DEFAULT)." >&2; fi; fi; [ -z "$TARGET" ] && TARGET="$DEFAULT"; git fetch origin "$TARGET" --quiet 2>/dev/null || true; echo "=== Comparing current branch against: $TARGET ==="; git diff "$TARGET"...HEAD || echo "[warn] Diff failed for $TARGET...HEAD"`

If third-party or unfamiliar APIs are present, and context7 MCP tools are available, resolve and fetch only the minimal relevant documentation before finalizing recommendations.

Please provide a comprehensive code review of the above changes focusing on:
- Security vulnerabilities and potential attack vectors
- Code maintainability and readability
- Adherence to best practices and coding standards
- Performance implications
- Creative suggestions for improvements or additional features
- Opportunities informed by authoritative library docs (cite briefly if used)

Provide detailed, constructive feedback without making file changes.

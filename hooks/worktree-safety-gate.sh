#!/bin/bash
# Worktree Safety Gate - PreToolUse hook for Bash
# Blocks `git worktree add` if there are uncommitted changes or wrong path.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check commands that create worktrees
if ! echo "$COMMAND" | grep -qE 'git\s+worktree\s+add'; then
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Check for uncommitted changes
STATUS=$(git status --porcelain 2>/dev/null)
if [ -n "$STATUS" ]; then
  echo "BLOCKED: Working tree has uncommitted changes. Commit them before creating a worktree." >&2
  echo "Uncommitted files on the source branch will be silently orphaned during worktree operations." >&2
  echo "" >&2
  echo "Dirty files:" >&2
  echo "$STATUS" >&2
  exit 2
fi

# Enforce .worktrees/ directory convention
# Extract the path argument after `git worktree add`
WORKTREE_PATH=$(echo "$COMMAND" | sed -nE 's/.*git\s+worktree\s+add\s+(-[^ ]+\s+)*([^ ]+).*/\2/p')
if [ -n "$WORKTREE_PATH" ]; then
  # Resolve to absolute, then check it lives under .worktrees/
  ABS_PATH=$(realpath -m "$WORKTREE_PATH" 2>/dev/null || echo "$WORKTREE_PATH")
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  EXPECTED_PREFIX="${REPO_ROOT}/.worktrees/"
  if [[ "$ABS_PATH" != "${EXPECTED_PREFIX}"* ]]; then
    echo "BLOCKED: Worktrees must be created inside .worktrees/ directory." >&2
    echo "Got: $WORKTREE_PATH" >&2
    echo "Expected path under: .worktrees/" >&2
    exit 2
  fi
fi

exit 0

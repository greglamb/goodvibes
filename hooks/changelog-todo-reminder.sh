#!/bin/bash
# Changelog/TODO Reminder - PostToolUse hook for Bash
# After a git commit, warns if CHANGELOG.md or TODO.md were not included.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check after git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit\s'; then
  exit 0
fi

# Check if the commit succeeded by looking at tool_response
RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty')
if ! echo "$RESPONSE" | grep -qiE '(create mode|file changed|files changed|insertions|deletions)'; then
  # Commit likely failed — nothing to check
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Check if CHANGELOG.md or TODO.md were in the commit
LAST_COMMIT_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null)

# Extract commit type from the last commit message for CHANGELOG heuristic.
# The real criterion is user impact — this is a lossy proxy to reduce
# false-positive nagging on chore/docs/test/refactor commits. Authors judge.
LAST_COMMIT_MSG=$(git log -1 --pretty=%s 2>/dev/null)
COMMIT_TYPE=$(echo "$LAST_COMMIT_MSG" | grep -oE '^[a-z]+' | head -1)
IS_BREAKING=$(echo "$LAST_COMMIT_MSG" | grep -qE '^[a-z]+(\([^)]+\))?!:' && echo "yes" || echo "no")

IS_USER_FACING="no"
case "$COMMIT_TYPE" in
  feat|fix) IS_USER_FACING="yes" ;;
esac
if [ "$IS_BREAKING" = "yes" ]; then IS_USER_FACING="yes"; fi

WARNINGS=""
if [ "$IS_USER_FACING" = "yes" ] && ! echo "$LAST_COMMIT_FILES" | grep -q "CHANGELOG.md"; then
  WARNINGS="${WARNINGS}CHANGELOG.md was not updated in this commit. If this change has no user impact, dismiss. "
fi
if ! echo "$LAST_COMMIT_FILES" | grep -q "TODO.md"; then
  WARNINGS="${WARNINGS}TODO.md was not updated in this commit. "
fi

if [ -n "$WARNINGS" ]; then
  # Output as additional context (not blocking — exit 0)
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Documentation reminder: ${WARNINGS}Verify if this commit changes behavior that should be documented per project guidelines."
  }
}
EOF
fi

exit 0

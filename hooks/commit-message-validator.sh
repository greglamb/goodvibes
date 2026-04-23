#!/bin/bash
# Commit Message Validator - PreToolUse hook for Bash
# Blocks git commits that don't follow Conventional Commits format.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check git commit commands with -m flag
if ! echo "$COMMAND" | grep -qE 'git\s+commit\s'; then
  exit 0
fi

# Skip amend-only commits (no new message required)
if echo "$COMMAND" | grep -qE -- '--amend\s*$'; then
  exit 0
fi

# Extract the FIRST -m argument value (handles double or single quotes).
# Using grep -oE avoids sed's greedy .* which would otherwise capture the
# LAST -m flag in multi-`-m` commits (e.g. trailing Co-Authored-By).
MSG=$(echo "$COMMAND" \
  | grep -oE -- '-m[[:space:]]+"[^"]*"|-m[[:space:]]+'\''[^'\'']*'\''' \
  | head -1 \
  | sed -E 's/^-m[[:space:]]+["'\'']//; s/["'\'']$//')

# If using heredoc or other format, try to extract from $(cat <<
if [ -z "$MSG" ]; then
  MSG=$(echo "$COMMAND" | sed -nE "s/.*git\s+commit\s+.*-m\s+\"\\\$\(cat <<[^)]+\)\"//p")
  # Can't reliably parse heredocs — allow through
  if [ -z "$MSG" ]; then
    exit 0
  fi
fi

# Validate Conventional Commits format: type(scope): description or type: description
if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|test|chore|build|ci|perf|revert)(\([a-zA-Z0-9_-]+\))?!?:\s'; then
  echo "BLOCKED: Commit message does not follow Conventional Commits format." >&2
  echo "Expected: type(scope): description" >&2
  echo "Types: feat, fix, docs, style, refactor, test, chore, build, ci, perf, revert" >&2
  echo "Got: $MSG" >&2
  exit 2
fi

# Check first line length (72 char limit)
FIRST_LINE=$(echo "$MSG" | head -1)
if [ ${#FIRST_LINE} -gt 72 ]; then
  echo "BLOCKED: Commit message first line exceeds 72 characters (${#FIRST_LINE})." >&2
  echo "Line: $FIRST_LINE" >&2
  exit 2
fi

exit 0

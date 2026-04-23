#!/bin/bash
# Staging Guard - PreToolUse hook for Bash
# Warns when `git add -A` or `git add .` could sweep in sensitive files.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check broad git add commands
if ! echo "$COMMAND" | grep -qE 'git\s+add\s+(-A|--all|\.)'; then
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Check what would be staged
WOULD_ADD=$(git status --porcelain 2>/dev/null | grep '^?' | awk '{print $2}')
if [ -z "$WOULD_ADD" ]; then
  exit 0
fi

# Check for sensitive file patterns
SENSITIVE_PATTERNS='\.env$|\.env\.|credentials|\.pem$|\.key$|\.p12$|\.pfx$|\.secret|id_rsa|id_ed25519|\.aws/|\.ssh/'
MATCHES=$(echo "$WOULD_ADD" | grep -iE "$SENSITIVE_PATTERNS")

if [ -n "$MATCHES" ]; then
  echo "BLOCKED: git add -A would stage potentially sensitive files:" >&2
  echo "$MATCHES" >&2
  echo "" >&2
  echo "Stage files individually instead, or add these to .gitignore first." >&2
  exit 2
fi

exit 0

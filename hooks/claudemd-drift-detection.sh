#!/bin/bash
# CLAUDE.md Drift Detection - SessionStart hook
# Checks if CLAUDE.md exists and contains goodvibes-workflow markers.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Only check if CLAUDE.md exists (skip if project hasn't been initialized)
if [ ! -f "CLAUDE.md" ]; then
  exit 0
fi

# Check for goodvibes-workflow sentinel markers
if ! grep -q '<!-- goodvibes-workflow:start -->' CLAUDE.md 2>/dev/null; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "CLAUDE.md exists but is missing goodvibes-workflow markers. Run the goodvibes-workflow skill in validate mode to check for drift."
  }
}
EOF
fi

exit 0

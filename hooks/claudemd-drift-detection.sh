#!/bin/bash
# CLAUDE.md Drift Detection - SessionStart hook
# Checks if CLAUDE.md exists and contains Goodvibes project-setup markers.
# Recognizes both the current marker and the legacy goodvibes-workflow marker,
# prompting the migrate path when the legacy format is detected.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Only check if CLAUDE.md exists (skip if project hasn't been initialized)
if [ ! -f "CLAUDE.md" ]; then
  exit 0
fi

HAS_NEW=$(grep -q '<!-- goodvibes:project-setup:start -->' CLAUDE.md 2>/dev/null && echo "yes" || echo "no")
HAS_LEGACY=$(grep -q '<!-- goodvibes-workflow:start -->' CLAUDE.md 2>/dev/null && echo "yes" || echo "no")

MESSAGE=""
if [ "$HAS_LEGACY" = "yes" ] && [ "$HAS_NEW" = "no" ]; then
  MESSAGE="CLAUDE.md uses legacy <!-- goodvibes-workflow:* --> markers. Run the setup-project-guidelines skill in migrate mode to update them to <!-- goodvibes:project-setup:* -->."
elif [ "$HAS_NEW" = "no" ] && [ "$HAS_LEGACY" = "no" ]; then
  MESSAGE="CLAUDE.md exists but is missing goodvibes:project-setup markers. Run the setup-project-guidelines skill in validate or initialize mode."
fi

if [ -n "$MESSAGE" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$MESSAGE"
  }
}
EOF
fi

exit 0

#!/bin/bash
# Brainstorming Pre-Sync - PreToolUse hook for Skill
# Automatically runs `episodic-memory sync` before brainstorming skill executes.
# Replaces the retired vibeplan-pre-sync.sh from goodvibes-workflow.

INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty')

# Trigger for brainstorming (short or fully-qualified name)
if [ "$SKILL" != "brainstorming" ] && [ "$SKILL" != "goodvibes:brainstorming" ]; then
  exit 0
fi

# Run episodic-memory sync if available; degrade gracefully
if command -v episodic-memory &>/dev/null; then
  episodic-memory sync 2>&1
else
  # Not installed — skip silently (episodic-memory is optional)
  :
fi

exit 0

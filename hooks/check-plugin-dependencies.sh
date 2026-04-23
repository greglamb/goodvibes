#!/bin/bash
# Check Plugin Dependencies - SessionStart hook
# Warns (non-blocking) when external optional plugins aren't installed.
# Post-merge, goodvibes-workflow is absorbed into this plugin, so the only
# remaining external optional dependency is episodic-memory.

OPTIONAL_PLUGINS=("episodic-memory")
MISSING=()

for plugin in "${OPTIONAL_PLUGINS[@]}"; do
  if ! claude plugin list 2>/dev/null | grep -q "$plugin"; then
    MISSING+=("$plugin")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Optional plugins not installed (features that depend on them will degrade gracefully):" >&2
  for plugin in "${MISSING[@]}"; do
    echo "  - $plugin" >&2
  done
  echo "" >&2
  echo "Install with: claude plugin install <plugin>@<marketplace>" >&2
fi

exit 0

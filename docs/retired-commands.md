# Retired Commands

Commands from the goodvibes-workflow plugin that were retired in the post-merge restructure. Functionality absorbed into the named skills where applicable.

## /vibeplan

**Retired:** Folded into `goodvibes:brainstorming` skill.

The skill now includes the Pre-Flight (context check, applicable project-scoped skills re-read at 1% threshold, step announcement) and Post-Flight (design save, episodic-memory record, rejected-approaches logging, CLAUDE.md promotion-candidate surfacing) behaviors that `/vibeplan` previously provided as a wrapper.

**How to invoke equivalent behavior:** Trigger the brainstorming skill directly. The skill now auto-runs the full flow.

## /vibedebug

**Retired:** Dropped entirely. Not folded into any skill.

The `goodvibes:systematic-debugging` skill alone is sufficient for debugging workflows. The `_gitignored/debug/` convention that `/vibedebug` enforced is a personal habit, not a skill-level requirement — keep the folder and use it manually when helpful.

**How to invoke equivalent behavior:** Trigger systematic-debugging directly. If you use `_gitignored/debug/`, point the skill at it explicitly.

## /vibecheck

**Retired:** Folded into `goodvibes:verification-before-completion` skill.

The skill's checklist now includes project-standards compliance as item 2.

**How to invoke equivalent behavior:** Trigger verification-before-completion when acceptance criteria are complex or spec compliance matters.

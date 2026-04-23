---
name: verification-before-completion
description: Use only when formal acceptance criteria exist (spec, user story) or when spec compliance is contractually meaningful - Opus 4.7 self-verifies before reporting, so this skill is invoked explicitly rather than by default
---

# Verification Before Completion

Opus 4.7 performs internal self-verification by default. This skill is retained
only for cases where explicit acceptance-criteria checking matters: spec
compliance, contractual deliverables, or complex multi-module changes where
implicit verification may miss something.

## When to Invoke

Invoke explicitly only when:

- The task has a formal acceptance criteria list (from a user story or spec)
- Spec compliance is legally or contractually meaningful
- The task spans multiple modules where implicit verification may not cover
  cross-module interactions

For routine tasks, trust Opus 4.7's self-verification and skip this skill.

## Verification Checklist

When invoked, confirm each of the following and report status:

1. All acceptance criteria from the originating user story or spec are met
2. **Project standards compliance:** if a `project-standards` skill exists in
   the current project, read it and verify the changes conform to its
   conventions, coding style, and architectural rules. Report any violations
   as critical issues that block completion.
3. All tests written during this task pass
4. All pre-existing tests still pass (no regressions)
5. Documentation (README, CHANGELOG, inline comments where material) is updated
6. No deprecated APIs used

Report any failures with specific file and line references. Do not claim
completion if any item fails.

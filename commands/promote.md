---
description: Promote a mid-session discovery into the project's CLAUDE.md
argument-hint: [what-to-promote]
---
Promote a decision, convention, or preference from the current session into the project's CLAUDE.md so it survives compaction and future sessions.

Steps:
1. Read the current CLAUDE.md. Identify an appropriate section for the promotion target, or ask the user where to put it.
2. Show the user the proposed CLAUDE.md edit (diff-style preview).
3. Confirm with AskUserQuestion before writing.
4. If confirmed, write the update to CLAUDE.md.
5. If the discovery involves rejected approaches, ALSO log to TODO.md's Rejected Approaches section.
6. Report what was promoted and where.

Guidelines for what belongs in CLAUDE.md:
- Architectural invariants (not ephemeral design choices)
- Persistent conventions (style, naming, patterns)
- Long-standing user preferences
- Cross-cutting constraints (security, performance, compatibility)

What does NOT belong (keep in session or TODO.md):
- Task-specific notes
- Time-bounded decisions ('for this feature we'll do X')
- Individual bug investigations
- Open questions (those go in TODO.md's Blocked section)

Argument: $ARGUMENTS

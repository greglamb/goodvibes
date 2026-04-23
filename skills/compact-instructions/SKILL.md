---
name: compact-instructions
description: >
  Injects project-specific preservation guidance when the session is about to
  be compacted. Activates before /compact runs or when the agent detects
  approaching context limit. Ensures architectural decisions, rejected
  alternatives, and exact identifiers survive summarization.
triggers:
  - Before any invocation of /compact
  - When context usage exceeds 70% and compaction is imminent
  - When the user explicitly requests "save context" or similar
---

# Compact Instructions

Goodvibes assumes a compact-heavy workflow: single sessions may span weeks or
months, with many compaction events. The summarization sub-agent benefits from
explicit instructions about what to preserve.

## Done Looks Like

- Compact instructions have been stated in the current turn
- Key architectural decisions from the current session are captured in
  canonical storage (design doc, ADR, or explicit note)
- Rejected alternatives with rationale are captured
- Exact identifiers needed for resumption are listed

## What to Preserve

When this skill activates, remind the summarization sub-agent to preserve:

1. **Architectural decisions AND their rationale.** Not just "we chose X" but
   "we chose X because Y and rejected Z because W." Rationale is what prevents
   re-litigation after compaction.

2. **Rejected alternatives.** The options considered and rejected are often the
   first thing compaction drops. Preserving them prevents rediscovering the
   same dead ends.

3. **Exact identifiers.** File paths, function names, test names, error
   strings, URLs, IDs. Compaction often paraphrases these; your handoff is
   the canonical copy.

4. **Open threads explicitly deferred.** Distinguish "we decided not to do X"
   from "we forgot X." The latter should be promoted to a task list.

5. **User preferences discovered mid-session.** Conventions, style choices,
   or constraints the user stated that aren't in CLAUDE.md yet. Flag these
   for promotion.

## What to Discard

Equally important, the summarization sub-agent should aggressively drop:

1. **Tool output that has been acted on.** Old `ls` results, grep output,
   transient file contents.
2. **Back-and-forth clarification exchanges.** Only the clarified intent matters.
3. **Debugging attempts that failed and were abandoned** unless they represent
   a rejected alternative worth preserving.

## Promotion to CLAUDE.md

When this skill runs, also consider whether any decisions or preferences from
the current session should be promoted to CLAUDE.md so they survive beyond
compaction entirely. If yes, state which ones and ask the user to confirm
before promoting.

## Output Format

When invoked explicitly (not automatically pre-compact), produce a structured
note in this format:

### Session Checkpoint

**Feature arc:** <one sentence on what this session segment is solving>

**Decisions with rationale:**
- <decision>: <rationale>

**Rejected alternatives:**
- <alternative>: <why rejected>

**Open threads (explicitly deferred):**
- <thread>

**CLAUDE.md promotion candidates:**
- <item> — <why it should be promoted>

**Next concrete step:**
<verbatim, copy-pasteable, with exact file paths and commands>

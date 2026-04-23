# Upstream Divergence Log

This file tracks every intentional divergence of Goodvibes from upstream
`obra/superpowers`. When upstream releases new versions, review this log
before merging or cherry-picking to understand which changes are intentional.

## Format

Each entry: `### <short title>` heading, followed by:
- **Date:** YYYY-MM-DD
- **Upstream behavior:**
- **Goodvibes behavior:**
- **Rationale:**
- **Files affected:**

---

### Plan execution defaults to inline

- **Date:** 2026-04-23
- **Upstream behavior:** `writing-plans` skill hardcodes subagent-driven-development
  as the required execution mode for every plan (Superpowers v5, issue #1044).
- **Goodvibes behavior:** `writing-plans` defaults to inline execution via
  `executing-plans`. Subagent-driven is opt-in and reserved for high-risk
  or unfamiliar changes.
- **Rationale:** Opus 4.7 prefers focused one-response work over fanning out.
  Mandatory subagent dispatching creates wall-clock overhead without
  proportional quality gain for typical tasks.
- **Files affected:**
  - `skills/writing-plans/SKILL.md`
  - `skills/subagent-driven-development/SKILL.md`
  - `skills/executing-plans/SKILL.md`

### Verification ceremony reduced

- **Date:** 2026-04-23
- **Upstream behavior:** `verification-before-completion` skill invoked on
  every task completion.
- **Goodvibes behavior:** Skill reduced to a short acceptance-criteria checklist.
  Full verification ceremony removed.
- **Rationale:** Opus 4.7 self-verifies before reporting (confirmed by Anthropic
  and observed by Intuit, Vercel teams). The upstream skill largely duplicates
  native model behavior and adds latency.
- **Files affected:**
  - `skills/verification-before-completion/SKILL.md`

### Thinking-prompt language removed

- **Date:** 2026-04-23
- **Upstream behavior:** Skills contain "think carefully," "take your time,"
  "think step by step" language intended to induce deeper reasoning.
- **Goodvibes behavior:** These phrases removed globally.
- **Rationale:** Opus 4.7 uses adaptive thinking that cannot be disabled and
  ignores or over-responds to such prompts. Explicit thinking language is
  redundant at best, counterproductive at worst.
- **Files affected:** No redundant thinking-prompt language remained in upstream
  skills at the time of this fork; no removals were required. "Done Looks Like"
  sections added to all preserved skills:
  - `skills/brainstorming/SKILL.md`
  - `skills/dispatching-parallel-agents/SKILL.md`
  - `skills/executing-plans/SKILL.md`
  - `skills/finishing-a-development-branch/SKILL.md`
  - `skills/receiving-code-review/SKILL.md`
  - `skills/requesting-code-review/SKILL.md`
  - `skills/subagent-driven-development/SKILL.md`
  - `skills/systematic-debugging/SKILL.md`
  - `skills/test-driven-development/SKILL.md`
  - `skills/using-git-worktrees/SKILL.md`
  - `skills/writing-plans/SKILL.md`
  - `skills/writing-skills/SKILL.md`
  "Scope Boundaries" sections added to code-modifying skills:
  - `skills/test-driven-development/SKILL.md`
  - `skills/executing-plans/SKILL.md`
  - `skills/subagent-driven-development/SKILL.md`

### Framework identity renamed to "goodvibes"

- **Date:** 2026-04-23
- **Upstream behavior:** Framework is named "Superpowers" in plugin manifest,
  command namespace, agent namespace, skill cross-references, and prose.
- **Goodvibes behavior:** Framework renamed to "goodvibes" throughout, with
  the exceptions documented below.
- **Rationale:** Personal-use fork with a distinct identity and philosophy;
  shared namespace with upstream creates confusion when both are referenced.
- **Preserved as "Superpowers":**
  - Upstream repo URL (`obra/superpowers`)
  - LICENSE attribution
  - Fork notice in README
  - All "Upstream behavior:" sections in this file
  - Comparative prose ("Goodvibes is Superpowers retuned for…")
  - Historical context (upstream issue URLs, e.g., issues/571 and issue #1044)
  - Legacy-skills migration warning in `hooks/session-start`
    (points users at `~/.config/superpowers/skills` so they can migrate)
- **Files affected:** See the commit for full file list. Primary renames:
  - `skills/using-superpowers/` → `skills/using-goodvibes/`
  - `docs/superpowers/` → `docs/goodvibes/`
  - Plugin manifest identity (`.claude-plugin/plugin.json`, `marketplace.json`)
  - `package.json` `name` and `main` fields
  - Command and agent namespace prefixes
  - `hooks/session-start` injection strings and skill path
  - `scripts/sync-to-codex-plugin.sh` publishing identity
  - All skill cross-references and prose self-references
  - `tests/**` and `docs/**`

### Compact-instructions skill added

- **Date:** 2026-04-23
- **Upstream behavior:** No specific handling for compact-heavy workflows.
- **Goodvibes behavior:** New `compact-instructions` skill that injects
  project-specific preservation guidance before `/compact` runs.
- **Rationale:** Greg's workflow relies on compact-only session management
  over multi-month conversations. The summarization sub-agent benefits from
  explicit instructions about what architectural context to preserve.
- **Files affected:**
  - `skills/compact-instructions/SKILL.md` (new)

### goodvibes-workflow absorbed into fork

- **Date:** 2026-04-23
- **Upstream behavior:** N/A (goodvibes-workflow is a Greg-authored plugin,
  not upstream).
- **Goodvibes behavior:** Hooks, CLAUDE.md injection skill, and commands
  from the standalone goodvibes-workflow plugin are now part of this fork.
  The standalone plugin is deprecated in a companion commit on
  `claude-gcode-tools` (branch `deprecate/goodvibes-workflow`).
- **Rationale:** Single plugin install, single update cycle, no namespace
  coordination between two plugins, cleaner distribution.
- **Files affected:** `hooks/`, `skills/setup-project-guidelines/`,
  `commands/*.md`, `docs/templates/`, `docs/retired-commands.md`.

### Thin-wrapper commands retired

- **Date:** 2026-04-23
- **Upstream behavior:** N/A.
- **Goodvibes behavior:** `/vibeplan` and `/vibecheck` retired; their sauce
  folded into `brainstorming` and `verification-before-completion`
  respectively. `/vibedebug` retired entirely without fold-in — the
  `systematic-debugging` skill alone is sufficient, and the
  `_gitignored/debug/` convention is a personal habit rather than a
  skill-level rule.
- **Rationale:** Thin wrappers around skills are redundant when the skill
  can be taught to do the same work natively. Where the wrapper added no
  durable value (vibedebug), dropping it outright is cleaner than folding
  in minor conventions that don't belong at the skill level.
- **Files affected:** `skills/brainstorming/`,
  `skills/verification-before-completion/`, `docs/retired-commands.md`.

### TODO.md sectioned format with Rejected Approaches

- **Date:** 2026-04-23
- **Upstream behavior:** N/A.
- **Goodvibes behavior:** TODO.md uses a sectioned format (Next Up, Blocked,
  Someday/Maybe, Known Limitations, Tech Debt, Rejected Approaches). The
  'no silent deferrals' rule extends to rejected alternatives — they must
  be logged with rationale.
- **Rationale:** Flat TODO lists don't scale across multi-month projects.
  Sectioned format enables section-level operations (archive, render).
  Rejected-approaches tracking prevents re-litigating settled design
  choices after compaction.
- **Files affected:** `skills/brainstorming/`, `skills/writing-plans/`,
  `skills/setup-project-guidelines/references/SETUP.md`,
  `docs/templates/TODO.md.template`, `commands/todo.md`,
  `commands/todo-archive.md`.

### Directive-based CHANGELOG discipline

- **Date:** 2026-04-23
- **Upstream behavior:** N/A.
- **Goodvibes behavior:** CHANGELOG discipline governed by an explicit
  directive file (`CHANGELOG_DIRECTIVES.md`) deployed to user projects.
  Rules: user-impact criterion (not commit type), user voice, Keep a
  Changelog layout (Added / Changed / Fixed / Removed), tag-time promotion
  of `[Unreleased]` to `## [vX.Y.Z] - YYYY-MM-DD` in the same commit the
  tag points at, and `chore(release): v<X.Y.Z>` as the release commit
  convention. The `changelog-todo-reminder` hook uses a feat/fix/breaking
  heuristic as a non-blocking reminder; authors judge user impact.
- **Rationale:** Commit-type heuristics are a lossy proxy for user impact.
  Explicit directive captures the real rule plus the release-time
  mechanics (tag-time promotion, release commit) that are otherwise easy
  to forget. Deploying as a project-root file makes the rules
  discoverable without opening skill internals.
- **Files affected:** `hooks/changelog-todo-reminder.sh`,
  `skills/setup-project-guidelines/references/SETUP.md`,
  `docs/templates/CHANGELOG.md.template`,
  `docs/templates/CHANGELOG_DIRECTIVES.md.template`, `commands/setup.md`.

### CLAUDE.md promotion workflow

- **Date:** 2026-04-23
- **Upstream behavior:** N/A.
- **Goodvibes behavior:** `/goodvibes:promote` command and skill integrations
  surface mid-session discoveries for promotion into the durable CLAUDE.md.
- **Rationale:** Compaction is lossy. Durable project memory (CLAUDE.md) is
  compaction-immune. The promotion workflow lets the user move important
  discoveries from conversation state into durable storage as a single
  confirmed action.
- **Files affected:** `commands/promote.md`, `skills/compact-instructions/`,
  `skills/brainstorming/`.

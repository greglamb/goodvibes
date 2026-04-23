# Changelog

## [Unreleased] - 2026-04-23

### Philosophy Shift

- Established Goodvibes as an opinionated fork of Superpowers, tuned for
  Opus 4.7 and compact-heavy workflows.
- `goodvibes-workflow` plugin absorbed into the fork. Single plugin going
  forward.

### Added

- `compact-instructions` skill for first-class compact-heavy workflow support
- `UPSTREAM_DIVERGENCE.md` tracking intentional forks from upstream
- Goodvibes Execution Preferences section in root CLAUDE.md
- "Done Looks Like" sections across 12 preserved skills
- "Scope Boundaries" sections on code-modifying skills
  (test-driven-development, executing-plans, subagent-driven-development)
- Six hooks from goodvibes-workflow: worktree-safety-gate,
  commit-message-validator, staging-guard, changelog-todo-reminder,
  claudemd-drift-detection, check-plugin-dependencies
- `brainstorming-pre-sync.sh` hook replacing the retired `vibeplan-pre-sync.sh`
- `setup-project-guidelines` skill (CLAUDE.md injection with sentinel markers,
  with initialize / validate / migrate modes)
- Eight commands under `/goodvibes:*` namespace: `commit`, `push`, `next`,
  `todo`, `todo-archive`, `backup`, `setup`, `create-standards`
- `/goodvibes:promote` command for CLAUDE.md promotion workflow
- TODO.md sectioned format with six named sections including Rejected Approaches
- Directive-based CHANGELOG discipline: user-impact criterion, user voice,
  Keep a Changelog layout, tag-time promotion, `chore(release): vX.Y.Z`
  convention
- `TODO.md`, `CHANGELOG.md`, and `CHANGELOG_DIRECTIVES.md` templates in
  `docs/templates/`; deployed by `/goodvibes:setup`
- `docs/retired-commands.md` documenting the three retired `/vibe*` commands

### Changed

- **BREAKING:** Framework identity renamed from "superpowers" to "goodvibes"
  throughout (plugin manifest, `package.json`, command namespace, agent
  namespace, skill cross-references, local artifact paths, hooks, scripts,
  tests, docs). Upstream attribution and comparative references preserved.
- **BREAKING:** `/vibe*` commands retired with no aliases. Use `/goodvibes:*`
  equivalents. See `docs/retired-commands.md` for the wrapper commands
  (`/vibeplan`, `/vibecheck`) folded into skills, and `/vibedebug` which
  was retired entirely without a replacement (use `systematic-debugging`
  skill directly).
- Plan execution defaults to inline via `executing-plans`; subagent-driven
  is opt-in
- `verification-before-completion` reduced to a gated checklist invoked
  explicitly for spec-compliance cases; checklist item 2 added for
  project-standards compliance
- Session-start hook injection updated to reference `using-goodvibes`
- `setup-project-guidelines` skill recognizes legacy
  `<!-- goodvibes-workflow:* -->` markers and offers a migrate mode
- Brainstorming skill gains Pre-Flight (context check, 1%-threshold
  project-scoped skills re-read, step announcement) and Post-Flight
  (design save, episodic-memory record, rejected-approaches logging,
  CLAUDE.md promotion-candidate surfacing) behaviors
- Writing-plans skill logs rejected plan alternatives
- `check-plugin-dependencies` hook simplified to check only external
  optional plugins (`episodic-memory`); `superpowers` and `project-standards`
  dependency checks removed
- `changelog-todo-reminder` hook gates the CHANGELOG nag on
  `feat`/`fix`/breaking commit types with a dismissal hint; the TODO nag
  always fires
- 'No silent deferrals' rule extended to rejected approaches

### Deprecated

- `goodvibes-workflow` plugin in `claude-gcode-tools` marketplace
  (separate deprecation commit on `deprecate/goodvibes-workflow` branch in
  that repo)

### Removed

- Mandatory subagent-driven-development default from `writing-plans`
- `/vibeplan`, `/vibecheck` commands (folded into skills)
- `/vibedebug` command (retired without replacement)
- `/vibecommit`, `/vibepush`, `/vibenext`, `/vibetodo`, `/vibeclean`,
  `/vibebackup`, `/vibesetup`, `/vibecreatestandards` commands (renamed
  to `/goodvibes:*` equivalents)

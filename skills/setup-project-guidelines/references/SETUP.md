# Project Guidelines

## Required Skills and Workflows

- **project-standards** — Project-scoped skill containing this project's conventions, architecture rules, and coding standards. MUST be read before changing anything. Generate with `/goodvibes:create-standards <requirements>` if not yet present.
- **goodvibes** (this plugin, auto-active) — Provides brainstorming, planning, execution, test-driven development, code review, systematic debugging, verification, compact instructions, and the project-setup skill itself. Invoked via `/goodvibes:*` commands and `goodvibes:*` skill names.
- **episodic-memory** (optional external plugin) — Semantic search for Claude Code conversations. Remember past discussions, decisions, and patterns. If installed, invoke `/episodic-memory:remembering-conversations` to search memory.

### Skill Usage Rules

- If there is even a 1% chance a skill applies, invoke it.
- Read the SKILL.md file for each skill before using it.
- Announce each skill by name when activating it: "I'm using the [skill] skill to [purpose]."
- If a skill has a checklist, create a TodoWrite item per checklist entry.
- If a skill fails to activate, stop and report which skill did not trigger rather than continuing without it.

### Development Process

1. **Brainstorm** (`goodvibes:brainstorming`) — Always start here, even for "simple" tasks. The skill handles Pre-Flight (context check, re-read applicable project-scoped skills including `project-standards`, announce each phase) and Post-Flight (save design to `docs/goodvibes/plans/YYYY-MM-DD-<topic>-design.md`, record in episodic-memory if available, log rejected approaches to `TODO.md`, surface CLAUDE.md promotion candidates). Explore project context (files, docs, recent commits). Ask clarifying questions one at a time. Propose 2–3 approaches with trade-offs. Present design in sections scaled to complexity; get approval after each section.

2. **Worktree** (`goodvibes:using-git-worktrees`) — After design approval, create an isolated worktree. Run project setup and verify clean test baseline before writing any code. Announce ready status with test count.

3. **Plan** (`goodvibes:writing-plans`) — Break work into 2–5 minute tasks with exact file paths, complete code, and verification steps. All planned code must conform to `project-standards`. If alternative plan structures are considered and rejected during plan construction, log the rejection to `TODO.md` under `## Rejected Approaches` with date and rationale. Save plan to `docs/goodvibes/plans/YYYY-MM-DD-<feature-name>.md`. Each task must include: files to create/modify, failing test to write, minimal implementation, verification command, and commit step.

4. **Execute** — Default to inline execution via `goodvibes:executing-plans`. Subagent-driven execution (`goodvibes:subagent-driven-development`) is opt-in for tasks that touch unfamiliar code, span multiple modules, or are high-risk (production data, security-sensitive changes). See the Goodvibes Execution Preferences section in root CLAUDE.md.

5. **TDD** (`goodvibes:test-driven-development`) — Every task follows strict RED-GREEN-REFACTOR. Write failing test first, run it and watch it fail, write minimal code, run it and watch it pass, commit. Code written before its test must be deleted. No exceptions. No rationalizations.

6. **Code Review** (`goodvibes:requesting-code-review`) — Review between tasks. Check against plan. Report issues by severity. Critical issues block progress. Review must verify conformance with `project-standards`. Violations of project architecture or coding standards are critical issues that block progress.

7. **Finish** (`goodvibes:finishing-a-development-branch`) — Verify all tests pass. Present options: merge, PR, keep branch, or discard. Clean up worktree.

### Debugging (when issues arise during implementation)

- Use `goodvibes:systematic-debugging` for any non-trivial bug — 4-phase root-cause process. Do not guess-and-check.
- Use `goodvibes:verification-before-completion` when acceptance criteria are complex or spec compliance matters. It is optional for routine tasks; Opus 4.7 self-verifies natively.

### Additional Rules

- Commit after each passing task, not at the end.
- YAGNI — ruthlessly remove unnecessary features from designs.
- Stop immediately on blockers. Ask for clarification rather than guessing.
- When receiving code review feedback, use `goodvibes:receiving-code-review`.
- Do not skip worktree setup. Do not skip TDD. Do not skip code review.
- When brainstorming or planning, record rejected approaches with rationale in `TODO.md` under `## Rejected Approaches`. Rejected alternatives carry the same "no silent deferrals" weight as dropped scope.
- When a mid-session decision, convention, or constraint should outlive the current work, use `/goodvibes:promote` to move it into CLAUDE.md durably.

### Worktree Preferences

Worktree directory: `.worktrees/`

## Hook-Enforced Rules

The following rules are enforced mechanically by hooks and cannot be bypassed:

### Worktree Safety Gate (`PreToolUse` → `worktree-safety-gate.sh`)

Blocks `git worktree add` if:
1. Working tree has uncommitted changes (prevents silent orphaning of files)
2. Worktree path is not inside `.worktrees/` directory

If the hook blocks you:
- **Commit changes first** — do NOT stash, do NOT bypass
- If changes are WIP and shouldn't be committed, STOP and ask the user what to do
- After worktree merge/cleanup, verify the source branch still has all expected files

### Commit Message Validator (`PreToolUse` → `commit-message-validator.sh`)

Blocks `git commit` if the message does not follow Conventional Commits format:
- Required format: `type(scope): description`
- Allowed types: feat, fix, docs, style, refactor, test, chore, build, ci, perf, revert
- First line must be 72 characters or fewer

### Staging Guard (`PreToolUse` → `staging-guard.sh`)

Blocks `git add -A` / `git add .` if untracked files match sensitive patterns (`.env`, `.pem`, `.key`, credentials, SSH keys). Stage files individually instead.

### CHANGELOG/TODO Reminder (`PostToolUse` → `changelog-todo-reminder.sh`)

After each successful `git commit`, checks whether CHANGELOG.md and TODO.md were included. The CHANGELOG check is gated to `feat` / `fix` / breaking commits as a lossy proxy for user impact — authors remain responsible for judging real impact and dismissing when the change has none. The TODO check always fires. Non-blocking reminder.

### CLAUDE.md Drift Detection (`SessionStart` → `claudemd-drift-detection.sh`)

On session start, checks if CLAUDE.md exists but is missing `<!-- goodvibes:project-setup:start -->` markers (or has legacy `<!-- goodvibes-workflow:start -->` markers). Suggests running `setup-project-guidelines` in validate or migrate mode.

### Plugin Dependency Check (`SessionStart` → `check-plugin-dependencies.sh`)

On session start, verifies that external optional plugins (currently: `episodic-memory`) are installed. Warns if missing; dependent features degrade gracefully.

### Brainstorming Pre-Sync (`PreToolUse` → `brainstorming-pre-sync.sh`)

Automatically runs `episodic-memory sync` before the brainstorming skill executes (if `episodic-memory` is installed; silent no-op otherwise).

## Documentation Requirements

- **CHANGELOG.md**: Every user-facing change MUST be documented in `CHANGELOG.md` under `## [Unreleased]` in **user voice**, not commit-message voice. Example: "Captured window no longer appears stretched on non-Retina displays" — NOT "fix: use filter.pointPixelScale". Follow [Keep a Changelog](https://keepachangelog.com) layout. Sections in order: `### Added`, `### Changed`, `### Fixed`, `### Removed`. Omit empty sections within a dated release.

  Infrastructure-only changes (build config, dev-loop conveniences, internal refactors invisible to users) do NOT require CHANGELOG entries. The `changelog-todo-reminder` post-commit hook nags on `feat`/`fix`/breaking commits as a lossy reminder, but the real criterion is user impact — authors judge.

  **Tag-time promotion:** When cutting a release, promote `[Unreleased]` to a dated section in the SAME commit the tag points at. Section header format: `## [vX.Y.Z] - YYYY-MM-DD` (exact tag including the `v` prefix). Leave `[Unreleased]` empty with all four subsection headers present, ready for the next cycle.

  **Release commits:** Use `chore(release): v<X.Y.Z>` as the subject for a tag commit that only promotes CHANGELOG. Never squash the promotion into an unrelated commit. One commit, one purpose.

  Full rules and follow-ups live in `CHANGELOG_DIRECTIVES.md` at the project root (deployed by `/goodvibes:setup`).

- **TODO.md**: ALL deferred work, rejected alternatives, known limitations, and planned features MUST be tracked in TODO.md using the sectioned format defined below.

- **Deferred work rule**: Any task identified during implementation that is explicitly out of scope or deferred MUST be added to TODO.md before the work is considered complete. This includes: scope reductions, "fix later" decisions, discovered tech debt, follow-up improvements, **and rejected alternatives**. Never defer or reject work silently.

## TODO.md Structure

TODO.md uses a sectioned format for discoverability:

- `## Next Up` — actively queued work
- `## Blocked` — waiting on external dependency, decision, or other block
- `## Someday/Maybe` — ideas worth considering, no commitment
- `## Known Limitations` — intentional scope reductions documented for users
- `## Tech Debt` — internal debt to address eventually
- `## Rejected Approaches` — alternatives considered and rejected, with rationale (extends the "no silent deferrals" rule to rejections)

Each entry includes the date added in format `[YYYY-MM-DD]`. Entries may move between sections as status changes.

# Replication Guide: TODO/CHANGELOG Discipline + Worktree Protection

This document is a self-contained recipe for porting the `TODO.md`,
`CHANGELOG.md`, and worktree-protection features from the `goodvibes`
Claude Code plugin into another plugin. An agent reading only this file
should be able to produce a working equivalent.

The features form three loosely-coupled but interlocking systems:

| System | Purpose | Primary touchpoints |
|---|---|---|
| **TODO discipline** | Capture every deferred / rejected piece of work in a sectioned file that survives compaction | Template, slash commands, skill hooks, post-commit reminder |
| **CHANGELOG discipline** | Force user-voice, Keep-a-Changelog notes for every shipped behavior change; mechanize tag-time promotion | Template, directives file, post-commit reminder |
| **Worktree protection** | Make it structurally impossible to do code work outside an isolated, gitignored worktree | Setup command, blocking PreToolUse hook, skill flow gates, cleanup skill |

All three layers depend on a project-root `CLAUDE.md` that the agent
re-reads each session — the durable behavioral memory. Templates and
hooks are useless if the agent has nothing pointing at them at session
start.

---

## 1. Replication checklist (in dependency order)

Build in this order. Each step is independently verifiable.

1. **Plugin scaffold** — confirm the target plugin has the standard
   Claude Code directory layout: `commands/`, `hooks/`, `skills/`, and
   either a manifest under `.claude-plugin/` or equivalent. Hooks need a
   `hooks.json` (or single-file equivalent) wired into the harness.
2. **Templates** — drop three template files into `docs/templates/`:
   `TODO.md.template`, `CHANGELOG.md.template`,
   `CHANGELOG_DIRECTIVES.md.template`. (Section 4.)
3. **`/<plugin>:setup` command** — deploys the templates into the user's
   project root, creates `.worktrees/`, and adds it to `.gitignore`.
   (Section 5.)
4. **Hooks** — `changelog-todo-reminder.sh` (PostToolUse, non-blocking)
   and `worktree-safety-gate.sh` (PreToolUse, blocking). Register both in
   `hooks.json`. (Section 6.)
5. **Slash commands** — `/<plugin>:todo`, `/<plugin>:todo-archive`,
   `/<plugin>:promote`. (Section 7.)
6. **Skill wiring** — patch the brainstorming and plan-writing skills so
   they log rejected alternatives to `TODO.md`. Patch the worktree skill
   so it verifies gitignore status. Patch the finish-branch skill so it
   removes worktrees only on merge/discard. (Section 8.)
7. **CLAUDE.md guidelines** — the prose the setup flow injects into the
   user's project `CLAUDE.md`. Without this, the agent has no rules to
   follow. (Section 9.)
8. **Plugin's own dogfooding** — create a `TODO.md`, `CHANGELOG.md`, and
   `.gitignore` entry for `.worktrees/` at the plugin repo root. The
   plugin should follow the rules it imposes.

---

## 2. Mental model: why each layer exists

Understand this before changing details. The layers are deliberately
redundant.

- **Templates** give a deterministic starting shape so section names
  don't drift between projects.
- **The setup command** is the only thing the user has to remember; it
  installs everything else.
- **Slash commands** make daily operations cheap so the discipline isn't
  abandoned under pressure.
- **Skill wiring** turns "log rejected approaches" from a request into
  reflexive agent behavior.
- **Hooks** are the last line of defense — they catch the cases where
  the skills failed or were skipped. `worktree-safety-gate` *blocks*;
  `changelog-todo-reminder` *nags*. The asymmetry is intentional:
  worktree creation in the wrong place orphans work silently;
  documentation gaps are recoverable.
- **CLAUDE.md guidelines** make the whole system discoverable on every
  fresh session, surviving context compaction.

When adapting to a new plugin, preserve the layering even if you
rename pieces. Removing the hook because "the skill should be enough"
is a known failure mode — agents skip skills under pressure.

---

## 3. Naming conventions to substitute

The source plugin namespaces everything as `goodvibes`. When porting,
substitute these consistently:

| Source | Replace with |
|---|---|
| `/goodvibes:setup` | `/<your-plugin>:setup` |
| `/goodvibes:todo` | `/<your-plugin>:todo` |
| `/goodvibes:todo-archive` | `/<your-plugin>:todo-archive` |
| `/goodvibes:promote` | `/<your-plugin>:promote` |
| `/goodvibes:backup` | `/<your-plugin>:backup` (or inline `cp` if your plugin has no backup command — see notes under §7.2) |
| `_gitignored/_archive/todo/` | Keep as-is unless the plugin uses a different scratch dir |
| `<!-- goodvibes:project-setup:start -->` markers | `<!-- <your-plugin>:project-setup:start -->` |
| `docs/goodvibes/` | `docs/<your-plugin>/` |
| `${CLAUDE_PLUGIN_ROOT}` | Keep as-is; this is a Claude Code harness variable |

The `.worktrees/` directory name is a hard convention enforced by the
hook — do NOT rename it without also updating `worktree-safety-gate.sh`
and the worktree skill's discovery priority.

---

## 4. Templates (verbatim)

Create these three files under `docs/templates/`.

### 4.1 `docs/templates/TODO.md.template`

````markdown
# TODO

## Next Up

<!-- Actively queued work. Items here should be ready to start. -->

## Blocked

<!-- Waiting on external dependency, decision, or other block. Each entry should name what's blocking it. -->

## Someday/Maybe

<!-- Ideas worth considering, no commitment. Lowest priority. -->

## Known Limitations

<!-- Intentional scope reductions documented for users. These are features we've chosen not to build. -->

## Tech Debt

<!-- Internal debt to address eventually. Things that work but aren't right. -->

## Rejected Approaches

<!-- Alternatives considered and rejected, with rationale. Extends 'no silent deferrals' to rejections. -->

<!--
Entry format:
- [YYYY-MM-DD] Short description
  Detail: what it is, why it matters, blocker (if applicable), rationale (if rejected)
-->
````

**Rationale for these six sections:** they cover the lifecycle of work
that isn't currently happening. `Rejected Approaches` is the unusual
one — it exists to prevent re-litigating settled design decisions after
context compaction. Do not collapse it into `Someday/Maybe`.

### 4.2 `docs/templates/CHANGELOG.md.template`

````markdown
# Changelog

All notable user-facing changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [CalVer](https://calver.org/) versioning (`0.YYMM.DDBB`).

Write entries in user voice (not commit-message voice). Infrastructure-only
changes (build config, internal refactors, tests, tooling) do not produce
entries here — they live in git history. See CHANGELOG_DIRECTIVES.md for
the full rules.

## [Unreleased]

### Added

### Changed

### Fixed

### Removed
````

**Adaptation note:** if the target project uses SemVer instead of CalVer,
change line 6. Leave the empty subsections — they're the contract the
hook checks against.

### 4.3 `docs/templates/CHANGELOG_DIRECTIVES.md.template`

````markdown
# Directives — Changelog

Short, imperative rules for CHANGELOG discipline. Formal source is CLAUDE.md's "Documentation Requirements" section; this file exists to surface the directives in isolation for quick reference.

## Authoring

- **Document every user-facing change** in `CHANGELOG.md` under `## [Unreleased]`. If a change alters shipped behavior — fix, feature, UX, error message, install path, anything a user could notice — it has a CHANGELOG entry. Enforced by the `changelog-todo-reminder` post-commit hook (non-blocking reminder; don't rely on it exclusively).
- **Write in user voice, not commit-message voice.** "Captured window no longer appears stretched on non-Retina displays" — not "fix: use filter.pointPixelScale".
- **Follow [Keep a Changelog](https://keepachangelog.com) layout.** Sections in order: `### Added`, `### Changed`, `### Fixed`, `### Removed`. Omit empty sections within a release.
- **Infrastructure-only changes don't need CHANGELOG entries.** Build config, dev-loop conveniences, internal refactors invisible to users — skip. Post-commit hook will remind; answer "no user impact" and move on.

## Tag-time promotion (Keep a Changelog)

- **Promote `[Unreleased]` to a dated section in the SAME commit the tag points at.** Never push the tag first and the CHANGELOG update after.
- **Section header format: `## [vX.Y.Z] - YYYY-MM-DD`**, exact tag including the `v` prefix.
- **Leave `[Unreleased]` empty** after promotion, with the four subsection headers (`### Added`, `### Changed`, `### Fixed`, `### Removed`) present but empty, ready to receive the next cycle's entries.
- **On retag or release deletion, undo the promotion.** The CHANGELOG must not have a dated section for a tag that no longer exists.

## Release commits

- **`chore(release): v<X.Y.Z>`** is the conventional subject for a tag commit that only promotes CHANGELOG and bumps nothing else.
- **Never squash the promotion into an unrelated commit.** One commit, one purpose: the tag should be easy to audit.

## Follow-ups

- **TODO**: add a pre-push hook (or a `bin/release` wrapper) that refuses to push a `v*` tag when `[Unreleased]` hasn't been promoted, so the "promote in the tag commit" rule is mechanically enforced rather than relying on the author to remember. Current hook (`changelog-todo-reminder`) only fires post-commit and is non-blocking.
````

---

## 5. The setup command

### 5.1 `commands/setup.md`

The setup command is the single user-facing entry point. It is idempotent:
running it on an already-set-up project produces no destructive changes.

````markdown
---
description: Setup the development environment
---
Before continuing, do the following exactly once:

1. Check if the project root is a git repository (look for `.git/`). If not, run `git init`.
2. Create the `.worktrees` directory in the project root and add it to `.gitignore`.
3. Create the `_gitignored` directory in the project root and add `_gitignored` to `.gitignore`.
4. Create `TODO.md` in the project root from the template at `${CLAUDE_PLUGIN_ROOT}/docs/templates/TODO.md.template`. Do not overwrite if `TODO.md` already exists — in that case, inform the user that `TODO.md` exists and offer to migrate it to the sectioned format.
5. Create `CHANGELOG.md` in the project root from the template at `${CLAUDE_PLUGIN_ROOT}/docs/templates/CHANGELOG.md.template`. Do not overwrite if `CHANGELOG.md` already exists.
5b. Create `CHANGELOG_DIRECTIVES.md` in the project root from the template at `${CLAUDE_PLUGIN_ROOT}/docs/templates/CHANGELOG_DIRECTIVES.md.template`. Overwrite if an existing copy is older than the template (use a content diff; offer the user a preview before writing). This file is the quick-reference companion to CLAUDE.md's Documentation Requirements section.
6. Inject project guidelines into `CLAUDE.md` (see Section 9 for the content to inject, wrapped in sentinel markers).
````

**Adaptation notes:**

- Steps 2–3 establish the directory conventions the rest of the system
  relies on. The `_gitignored` directory is where the todo-archive
  command parks archived items; keep it gitignored so archived TODOs
  don't pollute history.
- Step 5b's "overwrite if older" behavior matters: directive files
  improve over time and should propagate to existing projects.
- The original setup command had additional steps for pre-commit/gitleaks
  setup. Those are independent of the TODO/CHANGELOG/worktree features —
  port them only if relevant to the target plugin's scope.

### 5.2 Directory conventions established

After setup runs, the user's project root contains:

```
project-root/
├── .gitignore           # includes .worktrees/ and _gitignored/
├── .worktrees/          # empty, will hold isolated workspaces
├── _gitignored/         # scratch space (todo-archive uses this)
├── CLAUDE.md            # injected with project-setup markers
├── CHANGELOG.md         # from template
├── CHANGELOG_DIRECTIVES.md  # from template
└── TODO.md              # from template
```

---

## 6. Hooks

Both hooks live under `hooks/` and are wired in `hooks/hooks.json`. The
worktree hook is **blocking** (exit 2 cancels the tool call); the
changelog/TODO hook is **non-blocking** (emits `additionalContext` only).

### 6.1 `hooks/worktree-safety-gate.sh`

````bash
#!/bin/bash
# Worktree Safety Gate - PreToolUse hook for Bash
# Blocks `git worktree add` if there are uncommitted changes or wrong path.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check commands that create worktrees
if ! echo "$COMMAND" | grep -qE 'git\s+worktree\s+add'; then
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Check for uncommitted changes
STATUS=$(git status --porcelain 2>/dev/null)
if [ -n "$STATUS" ]; then
  echo "BLOCKED: Working tree has uncommitted changes. Commit them before creating a worktree." >&2
  echo "Uncommitted files on the source branch will be silently orphaned during worktree operations." >&2
  echo "" >&2
  echo "Dirty files:" >&2
  echo "$STATUS" >&2
  exit 2
fi

# Enforce .worktrees/ directory convention
# Extract the path argument after `git worktree add`
WORKTREE_PATH=$(echo "$COMMAND" | sed -nE 's/.*git\s+worktree\s+add\s+(-[^ ]+\s+)*([^ ]+).*/\2/p')
if [ -n "$WORKTREE_PATH" ]; then
  # Resolve to absolute, then check it lives under .worktrees/
  ABS_PATH=$(realpath -m "$WORKTREE_PATH" 2>/dev/null || echo "$WORKTREE_PATH")
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  EXPECTED_PREFIX="${REPO_ROOT}/.worktrees/"
  if [[ "$ABS_PATH" != "${EXPECTED_PREFIX}"* ]]; then
    echo "BLOCKED: Worktrees must be created inside .worktrees/ directory." >&2
    echo "Got: $WORKTREE_PATH" >&2
    echo "Expected path under: .worktrees/" >&2
    exit 2
  fi
fi

exit 0
````

**Critical details:**

- The hook depends on `jq` and standard Unix tools. The Claude Code
  harness runs hooks in a context where these are typically available;
  if porting to a constrained environment, replace `jq` parsing with
  whatever is available.
- `exit 2` is the contract for "block the tool call." `exit 0` lets it
  through. Anything else is treated as an error and may or may not block
  depending on harness version — always use 0 or 2.
- The `sed -nE 's/.*git\s+worktree\s+add\s+(-[^ ]+\s+)*([^ ]+).*/\2/p'`
  pattern skips leading flags. It is not bulletproof for exotic flag
  forms (`--option=value` etc.) but covers the common cases.
- `realpath -m` resolves the path without requiring it to exist (the
  worktree directory hasn't been created yet at this point).
- Make it executable: `chmod +x hooks/worktree-safety-gate.sh`.

### 6.2 `hooks/changelog-todo-reminder.sh`

````bash
#!/bin/bash
# Changelog/TODO Reminder - PostToolUse hook for Bash
# After a git commit, warns if CHANGELOG.md or TODO.md were not included.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check after git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit\s'; then
  exit 0
fi

# Check if the commit succeeded by looking at tool_response
RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty')
if ! echo "$RESPONSE" | grep -qiE '(create mode|file changed|files changed|insertions|deletions)'; then
  # Commit likely failed — nothing to check
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  cd "$CWD" || exit 0
fi

# Check if CHANGELOG.md or TODO.md were in the commit
LAST_COMMIT_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null)

# Extract commit type from the last commit message for CHANGELOG heuristic.
# The real criterion is user impact — this is a lossy proxy to reduce
# false-positive nagging on chore/docs/test/refactor commits. Authors judge.
LAST_COMMIT_MSG=$(git log -1 --pretty=%s 2>/dev/null)
COMMIT_TYPE=$(echo "$LAST_COMMIT_MSG" | grep -oE '^[a-z]+' | head -1)
IS_BREAKING=$(echo "$LAST_COMMIT_MSG" | grep -qE '^[a-z]+(\([^)]+\))?!:' && echo "yes" || echo "no")

IS_USER_FACING="no"
case "$COMMIT_TYPE" in
  feat|fix) IS_USER_FACING="yes" ;;
esac
if [ "$IS_BREAKING" = "yes" ]; then IS_USER_FACING="yes"; fi

WARNINGS=""
if [ "$IS_USER_FACING" = "yes" ] && ! echo "$LAST_COMMIT_FILES" | grep -q "CHANGELOG.md"; then
  WARNINGS="${WARNINGS}CHANGELOG.md was not updated in this commit. If this change has no user impact, dismiss. "
fi
if ! echo "$LAST_COMMIT_FILES" | grep -q "TODO.md"; then
  WARNINGS="${WARNINGS}TODO.md was not updated in this commit. "
fi

if [ -n "$WARNINGS" ]; then
  # Output as additional context (not blocking — exit 0)
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Documentation reminder: ${WARNINGS}Verify if this commit changes behavior that should be documented per project guidelines."
  }
}
EOF
fi

exit 0
````

**Critical details:**

- The CHANGELOG check is gated on Conventional Commits prefixes
  (`feat`, `fix`, or breaking `!:`) because nagging on every chore/docs
  commit trains the user to dismiss reminders reflexively. The TODO
  check always fires — TODO updates are cheaper and the false-positive
  cost is low.
- `git diff-tree --no-commit-id --name-only -r HEAD` lists the files in
  the just-created commit. If the target plugin runs commits in an
  unusual way (e.g., direct API), this may need adjustment.
- The JSON output shape is the Claude Code harness contract for
  PostToolUse `additionalContext`. The agent receives this as context on
  its next turn.
- `chmod +x hooks/changelog-todo-reminder.sh`.

### 6.3 `hooks/hooks.json` registration

````json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/worktree-safety-gate.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/changelog-todo-reminder.sh"
          }
        ]
      }
    ]
  }
}
````

If the target plugin already has hooks registered for `Bash`, **append**
the new entries to the existing matcher's `hooks` array rather than
creating a duplicate matcher block. Order within a matcher matters: the
worktree gate should run early (it's the most likely to block).

---

## 7. Slash commands

Each command lives as a single markdown file under `commands/` with
frontmatter declaring the description and (optionally) argument hint.

### 7.1 `commands/todo.md`

````markdown
---
description: View TODO.md with section-aware rendering
---
FIRST Use the AskUserQuestion tool to determine how the user wants to view TODO.md:
- "Open in VS Code" → run `!code TODO.md`
- "Show here (all sections)" → print full contents in your reply verbatim inside a code block
- "Show a specific section" → follow up with which section (Next Up, Blocked, Someday/Maybe, Known Limitations, Tech Debt, Rejected Approaches)

For "show here" options, use bash to cat the file (or cat + section grep), then repeat the content in your reply. Do not rely on the view tool's output alone — the user needs the content in prose for downstream reasoning.
````

### 7.2 `commands/todo-archive.md`

````markdown
---
description: Archive completed items from a TODO.md section
argument-hint: [section-name]
---
Archive completed items from TODO.md. If no section is specified, ask which section to archive from (Next Up, Blocked, Someday/Maybe, Known Limitations, Tech Debt, Rejected Approaches).

Steps:
1. Back up TODO.md to `_gitignored/_archive/todo/` with a timestamped filename (e.g., `cp TODO.md _gitignored/_archive/todo/TODO-$(date +%Y%m%d-%H%M%S).md`). Create the directory if it doesn't exist.
2. Read TODO.md
3. Within the specified section, move completed items (those marked with [x] or with "(done)" or similar completion markers) to an archive file at:
   _gitignored/_archive/todo/<section>-archive.md
4. Remove the archived items from TODO.md
5. Report what was archived

Do not archive items from sections the user didn't specify. Do not delete items without archiving them to the archive file.
````

**Note:** The source plugin had a separate `/goodvibes:backup` command
that step 1 invoked. The inline `cp` above is equivalent and removes the
dependency. If your plugin has its own backup command, substitute it.

### 7.3 `commands/promote.md`

````markdown
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
````

**Why this command exists:** session context is lost on compaction.
CLAUDE.md is compaction-immune. The promote command is the explicit
hand-off from ephemeral to durable memory. Step 5 is the only link
between `/promote` and `TODO.md` — preserve it.

---

## 8. Skill wiring

The hooks catch failures; the skills are where the discipline becomes
reflexive. Three integration points must be added.

### 8.1 Brainstorming skill — log rejected approaches

In the skill's Post-Flight section, add a step that fires after the
design is approved:

> **Log rejected approaches:** For each alternative considered and
> rejected during the brainstorm, add an entry to `TODO.md` under
> `## Rejected Approaches` with the date, the rejected approach, and the
> rationale. Wires the "no silent rejections" rule into behavior.

Pair this with a "Surface promotion candidates" step that offers to run
`/promote` for any architectural invariants discovered.

### 8.2 Writing-plans skill — log rejected plan structures

Add a "Rejected Approaches Logging" section:

> If an alternative plan structure is considered and rejected during
> plan construction (e.g., "we could batch these tasks but chose to keep
> them separate because…"), log the rejection to `TODO.md` under
> `## Rejected Approaches` with date and rationale.
>
> This extends the 'no silent deferrals' rule to plan-level decisions.

### 8.3 Worktree skill — verify gitignore + flow gate

The skill that creates worktrees must:

1. **Discover the directory** in priority order: existing `.worktrees/`,
   existing `worktrees/`, CLAUDE.md preference, ask user.
2. **Verify the chosen directory is gitignored** via `git check-ignore -q .worktrees`
   before creating the worktree. If not ignored, add to `.gitignore` and
   commit BEFORE the worktree creation.
3. **Run project setup** in the new worktree (auto-detect package.json /
   Cargo.toml / pyproject.toml / go.mod).
4. **Verify a clean test baseline** — refuse to start work on a broken
   tree without explicit user permission.

Mark this skill as REQUIRED from `brainstorming`, `writing-plans`,
`executing-plans`, and `subagent-driven-development`. The structural
requirement is what makes the hook a backstop rather than the primary
defense.

### 8.4 Finishing-a-development-branch skill — conditional worktree cleanup

The finish skill should present options (merge / PR / keep / discard)
and remove the worktree **only on merge or discard**. For "keep branch"
or "PR open", preserve the worktree and report its path. Removing a
worktree the user still needs is listed as a Red Flag.

### 8.5 Setup-project-guidelines skill (optional)

If the target plugin has a "inject CLAUDE.md guidelines" skill, that's
the natural place to put the prose from Section 9. The source plugin
uses sentinel markers (`<!-- goodvibes:project-setup:start -->` and
`...:end`) so the injection is re-runnable and the agent can detect
drift. Recommended pattern:

- On session start, check whether `CLAUDE.md` exists and contains the
  expected markers.
- If markers missing → suggest running `/setup` in initialize mode.
- If markers present but content drifted from the template → offer to
  migrate.

This drift-detection hook is optional but high-value. The source uses
`hooks/claudemd-drift-detection.sh` (SessionStart event).

---

## 9. CLAUDE.md content to inject

This is the prose that makes the whole system work — without it, the
agent has no rules to follow. The setup flow should inject this between
sentinel markers in the user's project `CLAUDE.md`.

````markdown
<!-- <your-plugin>:project-setup:start -->

## Development Process

Follow this canonical sequence for non-trivial work:

1. **Brainstorm** — Explore alternatives, propose 2–3 approaches, get approval. Log rejected approaches to `TODO.md`.
2. **Worktree** — Create an isolated worktree under `.worktrees/`. Verify clean test baseline.
3. **Plan** — Break work into 2–5 minute tasks with exact paths, code, and verification steps.
4. **Execute** — Implement task-by-task. TDD where applicable.
5. **Review** — Self-review or code-review skill before finishing.
6. **Finish** — Merge, PR, keep, or discard. Cleanup worktree if merging or discarding.

Do not skip worktree setup. Do not skip TDD. Do not skip code review.

## Documentation Requirements

- **CHANGELOG.md**: Every user-facing change MUST be documented under `## [Unreleased]` in **user voice**, not commit-message voice. Example: "Captured window no longer appears stretched on non-Retina displays" — NOT "fix: use filter.pointPixelScale". Follow Keep a Changelog layout. Sections in order: `### Added`, `### Changed`, `### Fixed`, `### Removed`. Omit empty sections within a dated release.

  Infrastructure-only changes (build config, dev-loop conveniences, internal refactors invisible to users) do NOT require CHANGELOG entries. The post-commit hook nags on `feat`/`fix`/breaking commits as a lossy reminder; authors judge actual user impact.

  **Tag-time promotion:** When cutting a release, promote `[Unreleased]` to a dated section in the SAME commit the tag points at. Section header: `## [vX.Y.Z] - YYYY-MM-DD`. Leave `[Unreleased]` empty with all four subsection headers, ready for the next cycle.

  **Release commits:** Use `chore(release): v<X.Y.Z>` for tag commits that only promote CHANGELOG. One commit, one purpose.

  Full rules live in `CHANGELOG_DIRECTIVES.md` at the project root.

- **TODO.md**: ALL deferred work, rejected alternatives, known limitations, and planned features MUST be tracked in TODO.md using the sectioned format below.

- **Deferred work rule**: Any task identified during implementation that is explicitly out of scope or deferred MUST be added to TODO.md before the work is considered complete. This includes scope reductions, "fix later" decisions, discovered tech debt, follow-up improvements, **and rejected alternatives**. Never defer or reject work silently.

## TODO.md Structure

TODO.md uses a sectioned format for discoverability:

- `## Next Up` — actively queued work
- `## Blocked` — waiting on external dependency, decision, or other block
- `## Someday/Maybe` — ideas worth considering, no commitment
- `## Known Limitations` — intentional scope reductions documented for users
- `## Tech Debt` — internal debt to address eventually
- `## Rejected Approaches` — alternatives considered and rejected, with rationale (extends "no silent deferrals" to rejections)

Each entry includes the date added in format `[YYYY-MM-DD]`. Entries may move between sections as status changes.

## Worktree Preferences

Worktree directory: `.worktrees/` (project-local, gitignored). Worktrees outside this directory are rejected by the `worktree-safety-gate` hook.

<!-- <your-plugin>:project-setup:end -->
````

---

## 10. Verification

After replication, verify each layer works end-to-end:

### 10.1 Templates deploy

Run `/setup` in a fresh git repo. Confirm:

- `TODO.md`, `CHANGELOG.md`, `CHANGELOG_DIRECTIVES.md` exist at the root
  and match the templates.
- `.worktrees/` exists and appears in `.gitignore`.
- `_gitignored/` exists and appears in `.gitignore`.
- `CLAUDE.md` contains the sentinel markers with injected content.

Re-run `/setup` — no destructive changes should occur.

### 10.2 Worktree hook blocks correctly

```bash
# Test 1: dirty tree blocks
echo "dirty" > newfile && git worktree add .worktrees/test -b test-branch
# Expected: BLOCKED: Working tree has uncommitted changes.

# Test 2: wrong path blocks
git stash && git worktree add /tmp/outside -b test-branch
# Expected: BLOCKED: Worktrees must be created inside .worktrees/

# Test 3: correct invocation succeeds
git worktree add .worktrees/feature -b feature
# Expected: success
```

### 10.3 Reminder hook fires correctly

```bash
# Test 1: feat commit without CHANGELOG → CHANGELOG warning fires
git commit -m "feat: add foo"

# Test 2: chore commit without CHANGELOG → no CHANGELOG warning
git commit -m "chore: tidy build script"

# Test 3: any commit without TODO touch → TODO warning fires
```

### 10.4 Skill wiring fires

Run a brainstorm that surfaces and rejects an alternative. Confirm a
new entry appears under `TODO.md`'s `## Rejected Approaches` with date
and rationale.

### 10.5 Commands work

- `/todo` renders the file (try the "specific section" path).
- `/todo-archive Tech Debt` archives completed `[x]` items from that
  section to `_gitignored/_archive/todo/`.
- `/promote` writes to `CLAUDE.md` after confirmation.

---

## 11. Adaptation guidance

### 11.1 Different commit conventions

The reminder hook detects user-facing commits via Conventional Commits
prefixes. If the target project uses a different convention (e.g.,
gitmoji, plain English subjects), rewrite the `IS_USER_FACING` logic
in §6.2. The simpler fallback is to always nag and let authors dismiss.

### 11.2 Different worktree directory

If the target project requires worktrees elsewhere (e.g., a global
`~/worktrees/`), update both:

- `worktree-safety-gate.sh` — change `EXPECTED_PREFIX`.
- The worktree skill — change the discovery priority order.
- `commands/setup.md` — change step 2.
- CLAUDE.md guidelines (§9) — update the Worktree Preferences section.

Keep all four in sync; drift between hook and skill is a common source
of confusion.

### 11.3 Plugin without a brainstorming/planning skill

The rejected-approaches discipline depends on having skills that
naturally surface alternatives. If the target plugin doesn't have a
brainstorming step, either:

- Add a lightweight "decision-logging" skill that prompts the agent to
  log rejected approaches whenever it presents multiple options to the
  user, OR
- Make the `/promote` command's "rejected approach" path more
  prominent, so manual logging is the primary entry point.

### 11.4 Plugin without slash commands

If the target environment doesn't support slash commands, fold the
`/todo`, `/todo-archive`, and `/promote` behaviors into skills. They
work as skills — they just have heavier invocation. The setup behavior
must remain reachable somehow; otherwise the templates never deploy.

### 11.5 Different harness (not Claude Code)

The hook JSON shape (`hookSpecificOutput.additionalContext`) is
Claude-Code-specific. For other harnesses:

- Replace the hook output with whatever the target harness uses to
  inject context into the next agent turn.
- The `exit 2` blocking convention is also Claude Code's; check the
  target harness's contract.
- The `${CLAUDE_PLUGIN_ROOT}` variable is Claude-Code-specific; replace
  with the equivalent.

The skill content (markdown prose) is harness-agnostic and ports
unchanged.

---

## 12. What NOT to change

These details look incidental but encode hard-won design decisions.
Resist the urge to "clean them up."

- **Six TODO sections.** Five is too few; seven introduces overlap.
  Specifically: don't collapse `Rejected Approaches` into
  `Someday/Maybe` — they have opposite semantics ("we chose not to"
  vs. "we might later").
- **Asymmetric hook behavior.** The worktree hook blocks; the reminder
  hook does not. Making them symmetric (both blocking, or both nagging)
  breaks the system: blocking on every commit-without-CHANGELOG trains
  the user to dismiss; nagging on bad worktree creation lets work get
  orphaned.
- **`feat`/`fix`/breaking gating** on the CHANGELOG check. The
  alternative — nag on every commit — was tried and produced reflex
  dismissal. Don't restore it.
- **The dismissal hint** in the reminder text ("If this change has no
  user impact, dismiss"). Without it, the agent treats the reminder as
  a hard requirement and writes spurious CHANGELOG entries for
  infrastructure-only commits.
- **The "Rejected Approaches" entry on `/promote`.** It's the only link
  between the promote command and the TODO file. Without it, rejected
  architectural alternatives vanish on compaction.
- **`.worktrees/` (with leading dot).** The hidden form is the
  preference; the worktree skill's discovery priority codifies this.
  Removing the dot version puts the worktree directory in the user's
  default `ls` output, which is noisy.

---

## 13. File manifest

Everything to create or modify:

```
docs/templates/TODO.md.template                    # new
docs/templates/CHANGELOG.md.template               # new
docs/templates/CHANGELOG_DIRECTIVES.md.template    # new
hooks/worktree-safety-gate.sh                      # new, chmod +x
hooks/changelog-todo-reminder.sh                   # new, chmod +x
hooks/hooks.json                                   # add registrations
commands/setup.md                                  # new (or extend existing)
commands/todo.md                                   # new
commands/todo-archive.md                           # new
commands/promote.md                                # new
skills/brainstorming/SKILL.md                      # patch Post-Flight
skills/writing-plans/SKILL.md                      # add Rejected Approaches Logging
skills/using-git-worktrees/SKILL.md                # new, or patch existing
skills/finishing-a-development-branch/SKILL.md     # patch cleanup logic
.gitignore                                         # add .worktrees/
TODO.md                                            # plugin's own (dogfood)
CHANGELOG.md                                       # plugin's own (dogfood)
```

The plugin's own `TODO.md` and `CHANGELOG.md` are not optional. A
plugin that imposes discipline on users without following it itself
will not be trusted, and the maintainers will get bug reports about
inconsistencies between the templates and the live files.

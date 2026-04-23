---
name: setup-project-guidelines
description: >
  Inject and maintain Goodvibes project guidelines in a project's CLAUDE.md file.
  Use whenever the user mentions Goodvibes setup, initialization, validation, or
  migration. Trigger on phrases like "set up goodvibes", "initialize project
  guidelines", "validate my CLAUDE.md", "migrate goodvibes-workflow markers",
  "add workflow guidelines", or any reference to ensuring CLAUDE.md contains the
  standard Goodvibes development process (brainstorming, worktrees, TDD, code
  review, episodic-memory integration). Also trigger when the user creates a
  new project and wants the standard development workflow, or when they suspect
  their CLAUDE.md is missing guidelines or still uses the old
  `<!-- goodvibes-workflow:* -->` markers.
---

# setup-project-guidelines

Ensures a project's `CLAUDE.md` contains the Goodvibes development guidelines from `references/SETUP.md`.

## How it works

The skill has three modes: **initialize**, **validate**, and **migrate**. All three are idempotent.

### Sentinel markers

The injected content is wrapped in markers so it can be detected and updated deterministically:

```
<!-- goodvibes:project-setup:start -->
(content from SETUP.md, possibly customized)
<!-- goodvibes:project-setup:end -->
```

These markers are the primary detection mechanism. Agent review is used as a secondary validation step to confirm completeness.

### Backwards compatibility

Projects that used the retired `goodvibes-workflow` plugin have the old markers:

```
<!-- goodvibes-workflow:start -->
...
<!-- goodvibes-workflow:end -->
```

**Validate mode** recognizes both old and new markers and offers migration.
**Migrate mode** performs the migration: old markers become new markers, content is refreshed from the current SETUP.md.
**Initialize mode** always writes new markers.

## Initialize mode

Use when the user wants to add Goodvibes guidelines to a project for the first time, or when no markers are detected in CLAUDE.md.

### Steps

1. Read `references/SETUP.md` from this skill's directory.
2. Check if `CLAUDE.md` exists at the project root.
   - If it doesn't exist, create it.
3. Search `CLAUDE.md` for `<!-- goodvibes:project-setup:start -->` or `<!-- goodvibes-workflow:start -->`.
   - If either is found, switch to **validate mode** (which will offer migration for old markers).
4. Ask the user if they want to customize the guidelines before injection. Examples:
   - Adding or removing skills from the "Required Skills" list
   - Changing the worktree directory
   - Adjusting documentation requirements
   - Adding project-specific rules to the "Additional Rules" section
5. If the user provides customizations, apply them to the SETUP.md content before injection.
6. Append the following to `CLAUDE.md`, preserving any existing content:

```
<!-- goodvibes:project-setup:start -->
{SETUP.md content, with any customizations applied}
<!-- goodvibes:project-setup:end -->
```

7. Confirm to the user what was added and where.

## Validate mode

Use when the user wants to verify their CLAUDE.md still contains the Goodvibes guidelines, or when initialize mode detects existing markers.

### Steps

1. Read `references/SETUP.md` from this skill's directory.
2. Read `CLAUDE.md` from the project root.
3. Detect which marker style is present:
   - `<!-- goodvibes:project-setup:start --> / :end -->` — current format
   - `<!-- goodvibes-workflow:start --> / :end -->` — legacy from retired plugin
   - Neither — inform the user and offer to run **initialize mode**
4. If legacy markers are found, report this and offer to run **migrate mode**.
5. Extract the content between the markers.
6. Review the extracted content against `references/SETUP.md` and check:
   - All required sections are present (Required Skills, Skill Usage Rules, Development Process, Debugging, Additional Rules, Documentation Requirements).
   - No critical steps have been removed (TDD, code review, worktree setup).
   - The development process order is intact (Brainstorm → Worktree → Plan → Execute → TDD → Code Review → Finish).
7. Report findings:
   - **All good**: Confirm guidelines are intact.
   - **Drift detected**: List what's missing or changed, and offer to update the block by replacing everything between the markers with a fresh copy of SETUP.md (re-applying any customizations the user specifies).

## Migrate mode

Use when validate mode detects the legacy `<!-- goodvibes-workflow:* -->` markers, or when the user explicitly asks to migrate old markers.

### Steps

1. Read `references/SETUP.md` from this skill's directory.
2. Read `CLAUDE.md` from the project root.
3. Locate the `<!-- goodvibes-workflow:start -->` and `<!-- goodvibes-workflow:end -->` markers.
4. Extract the content currently between the legacy markers (for reference — it reflects the old Superpowers v4/v5 methodology).
5. Ask the user whether they had applied customizations to the legacy block that should be preserved. If yes, capture them.
6. Replace the entire legacy block (including the old markers) with a fresh block using the new markers:

```
<!-- goodvibes:project-setup:start -->
{SETUP.md content, with any preserved customizations applied}
<!-- goodvibes:project-setup:end -->
```

7. Report to the user: the old markers are gone, the new markers are in place, and the content has been refreshed from the current SETUP.md (which includes post-restructure methodology, sectioned TODO format, and directive-based CHANGELOG discipline).

## Customization

The user may provide customizations at initialization, validation/update, or migration. When customizations are requested:

- Apply them to the SETUP.md content before writing to CLAUDE.md.
- Document what was customized in the output so the user has a record.
- During validation, if the content differs from the reference SETUP.md, ask the user whether the differences are intentional customizations or unintended drift before overwriting.

## Important details

- Never remove or overwrite existing CLAUDE.md content outside the markers. The markers define the skill's territory — everything else belongs to the user or other tools.
- If CLAUDE.md has content before the markers, preserve it exactly.
- If CLAUDE.md has content after the markers, preserve it exactly.
- When updating, replace only the content between (and including) the markers.
- During migrate mode, the legacy markers AND the legacy content are both replaced atomically — do not leave orphan markers.

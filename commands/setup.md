---
description: Setup the development environment
---
Before continuing, do the following exactly once:

1. Check if the project root is a git repository (look for `.git/`). If not, run `git init`.
2. Create the `.worktrees` directory in the project root and add it to `.gitignore`.
3. Create the `_gitignored` directory in the project root and add both `_gitignored` and `_reference` to `.gitignore` (the `_reference` entry is kept for backwards compatibility with existing projects).
4. Create `TODO.md` in the project root from the template at `${CLAUDE_PLUGIN_ROOT}/docs/templates/TODO.md.template`. Do not overwrite if `TODO.md` already exists — in that case, inform the user that `TODO.md` exists and offer to migrate it to the sectioned format.
5. Create `CHANGELOG.md` in the project root from the template at `${CLAUDE_PLUGIN_ROOT}/docs/templates/CHANGELOG.md.template`. Do not overwrite if `CHANGELOG.md` already exists.
5b. Create `CHANGELOG_DIRECTIVES.md` in the project root from the template at `${CLAUDE_PLUGIN_ROOT}/docs/templates/CHANGELOG_DIRECTIVES.md.template`. Overwrite if an existing copy is older than the template (use a content diff; offer the user a preview before writing). This file is the quick-reference companion to CLAUDE.md's Documentation Requirements section.
6. Inject project guidelines into `CLAUDE.md` using the `setup-project-guidelines` skill. If `CLAUDE.md` already contains the legacy `<!-- goodvibes-workflow:start -->` markers, use the skill's migrate mode to update them to the new `<!-- goodvibes:project-setup:start -->` format.
7. Verify the following capabilities are available:
   - `goodvibes` framework (this plugin — already active if you're running this command)
   - `project-standards` skill
     - Generate with: `/goodvibes:create-standards <requirements>`
   - `episodic-memory` (optional)
     - If desired: `/plugin install episodic-memory@<marketplace>`
8. Set up gitleaks pre-commit hook for secret detection:
   a. Check if `pre-commit` is installed by running `pre-commit --version`.
      - If not installed, try in this order:
        1. `brew install pre-commit`
        2. If brew is unavailable or fails: `uv tool install pre-commit`
        3. If uv is unavailable: `pipx install pre-commit`
      - Verify installation succeeded before continuing.
   b. Check if `.pre-commit-config.yaml` already exists in the repo root.
      - If it exists, append the gitleaks repo entry to the existing `repos` list (do not modify existing hooks).
      - If it doesn't exist, create it.
   c. Add/merge this configuration into `.pre-commit-config.yaml`:
      ```yaml
      repos:
        - repo: https://github.com/gitleaks/gitleaks
          rev: v8.21.2
          hooks:
            - id: gitleaks
      ```
   d. Check if `.gitleaks.toml` exists in the repo root.
      - If not, create one with an empty allowlist:
        ```toml
        title = "Gitleaks config"

        [allowlist]
          description = "Allowlisted patterns"
          paths = []
        ```
   e. Run `pre-commit install` to register the hook in `.git/hooks/`.
   f. Run `pre-commit run gitleaks --all-files` to verify it works and catch any existing secrets.
   g. If secrets are found, report them but do NOT auto-fix or remove them. List the findings and stop.
   h. Add `.pre-commit-config.yaml` and `.gitleaks.toml` to a commit with message:
      `chore: add gitleaks pre-commit hook for secret detection`
   - Constraints:
     - Do not install gitleaks globally — let pre-commit manage it.
     - Do not modify any existing hooks in `.pre-commit-config.yaml`.
     - Do not remove or alter `.gitignore`.

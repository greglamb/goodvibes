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

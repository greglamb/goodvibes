# Changelog

## [Unreleased] - 2026-04-23

### Philosophy Shift

- Established Goodvibes as an opinionated fork of Superpowers, tuned for
  Opus 4.7 and compact-heavy workflows.

### Added

- `compact-instructions` skill for first-class compact-heavy workflow support
- `UPSTREAM_DIVERGENCE.md` tracking intentional forks from upstream
- Goodvibes Execution Preferences section in root CLAUDE.md
- "Done Looks Like" sections across 12 preserved skills
- "Scope Boundaries" sections on code-modifying skills
  (test-driven-development, executing-plans, subagent-driven-development)

### Changed

- **BREAKING:** Framework identity renamed from "superpowers" to "goodvibes"
  throughout (plugin manifest, `package.json`, command namespace, agent
  namespace, skill cross-references, local artifact paths, hooks, scripts,
  tests, docs). Upstream attribution and comparative references preserved.
- Plan execution defaults to inline via `executing-plans`; subagent-driven
  is opt-in
- `verification-before-completion` reduced to a gated checklist invoked
  explicitly for spec-compliance cases
- Session-start hook injection updated to reference `using-goodvibes`

### Removed

- Mandatory subagent-driven-development default from `writing-plans`

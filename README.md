# Goodvibes

> **Fork Notice:** This project is a fork of [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent, retuned for Claude Opus 4.7 and compact-preserving workflows.
> See [LICENSE](./LICENSE) for copyright details.

## Philosophy

Goodvibes is Superpowers with less ceremony and more trust in the model.
It diverges from upstream on three core principles:

1. **Trust the model where it has earned it.** Opus 4.7 self-verifies, follows
   instructions literally, and prefers focused one-response work over fanning
   out to subagents. Goodvibes removes ceremony that duplicates this native
   behavior.

2. **Preserve disciplines that remain model-layer gaps.** Test-driven development
   (RED-GREEN-REFACTOR), four-phase systematic debugging, and Socratic
   brainstorming are not default model behaviors. Goodvibes keeps them mandatory.

3. **Optimize for long sessions.** Goodvibes assumes compact-heavy workflows
   where a single session spans weeks or months. Defaults favor continuity over
   session-reset discipline.

## Key Divergences from Upstream

| Area | Upstream (Superpowers v5) | Goodvibes |
|------|---------------------------|-----------|
| Plan execution default | Subagent-driven-development (mandatory) | Inline execution (subagent-driven is opt-in) |
| Verification ceremony | `verification-before-completion` always invoked | Trimmed; rely on Opus 4.7 self-verification |
| Thinking prompts | "Think carefully," "take your time" language | Removed; adaptive thinking handles this |
| Compact continuity | Not addressed | First-class `compact-instructions` skill |

Full divergence log: [UPSTREAM_DIVERGENCE.md](./UPSTREAM_DIVERGENCE.md)

## ⚠️ Disclaimer

This project was created to meet its author's specific use case and needs. It is important to note that it is provided 'as is' without guarantees. Therefore, any response to requests for support, new features, or bug fixes may be limited. You are free to use it at your discretion if you find it useful, but be aware that any ongoing maintenance or enhancements may not be prioritized.

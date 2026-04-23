---
description: View TODO.md with section-aware rendering
---
FIRST Use the AskUserQuestion tool to determine how the user wants to view TODO.md:
- "Open in VS Code" → run `!code TODO.md`
- "Show here (all sections)" → print full contents in your reply verbatim inside a code block
- "Show a specific section" → follow up with which section (Next Up, Blocked, Someday/Maybe, Known Limitations, Tech Debt, Rejected Approaches)

For "show here" options, use bash to cat the file (or cat + section grep), then repeat the content in your reply. Do not rely on the view tool's output alone — the user needs the content in prose for downstream reasoning.

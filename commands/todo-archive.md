---
description: Archive completed items from a TODO.md section
argument-hint: [section-name]
---
Archive completed items from TODO.md. If no section is specified, ask which section to archive from (Next Up, Blocked, Someday/Maybe, Known Limitations, Tech Debt, Rejected Approaches).

Steps:
1. Run: !/goodvibes:backup TODO.md _gitignored/_archive/todo/
2. Read TODO.md
3. Within the specified section, move completed items (those marked with [x] or with "(done)" or similar completion markers) to an archive file at:
   _gitignored/_archive/todo/<section>-archive.md
4. Remove the archived items from TODO.md
5. Report what was archived

Do not archive items from sections the user didn't specify. Do not delete items without archiving them to the archive file.

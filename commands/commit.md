---
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(git push:*)
  - Bash(git branch:*)
  - Bash(git diff --staged:*)
---
1. First, run `git diff` to see all changes (both staged and unstaged)
2. Analyze the diff to understand what changed
3. Write a commit message following the Conventional Commits standard based on the diff:
   - Rely upon and use the Gitmoji standard when writing your commit messages
   - Use format: `type(scope): description`
   - Types: feat, fix, docs, style, refactor, test, chore
   - Keep the first line under 72 characters
   - Add a blank line and bullet points for details if needed
4. Stage all changes with `git add -A`
5. Commit with the conventional commit message

---
name: git-commit-writer
description: >
  Writes conventional commit messages by analyzing staged changes or a diff.
  Auto-invokes when user says "write a commit", "commit message", "git commit",
  or asks to "commit this". Follows Conventional Commits 1.0 spec.
---

# Git Commit Writer

Analyze the staged diff or provided changes and write a commit message.

## Process

1. Run `git diff --staged` (or use provided diff)
2. Identify the primary change type
3. Identify the scope (module, file, or feature area)
4. Write a commit message

## Conventional Commits Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Types
- `feat` — new feature
- `fix` — bug fix
- `security` — security fix or hardening (use for IAM/GCP security changes)
- `refactor` — code change that neither fixes a bug nor adds a feature
- `docs` — documentation only
- `chore` — tooling, deps, CI
- `test` — adding or updating tests
- `perf` — performance improvement
- `revert` — reverts a previous commit

### Rules
- Subject: imperative mood, no period, max 72 chars
- Body: explain WHY not WHAT (the diff shows what)
- Breaking changes: add `BREAKING CHANGE:` footer
- Reference issues: `Closes #123` or `Refs JIRA-456` in footer

## Output

Provide 1 primary commit message + 1 alternative if the changes could
be interpreted differently. Let the user pick.

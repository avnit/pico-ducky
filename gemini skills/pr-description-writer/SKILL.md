---
name: pr-description-writer
description: >
  Generates clear, complete pull request descriptions from a branch diff or
  list of commits. Use when asked to "write a PR", "PR description",
  "pull request", or "describe these changes". Output is GitHub-flavored
  Markdown ready to paste.
---

# PR Description Writer

## Process

1. Get the diff: `git log main..HEAD --oneline` and `git diff main...HEAD`
2. Understand what changed and why
3. Generate the PR description

## PR Template

```markdown
## Summary
<!-- 2-3 sentences: what this PR does and why -->

## Changes
<!-- Bullet list of key changes — focus on intent not implementation -->
- 
- 

## Security Impact
<!-- Always include for GCP/infra changes — what attack surface changed? -->
- [ ] No security impact
- [ ] IAM changes (describe)
- [ ] Network changes (describe)
- [ ] New external dependencies (describe)

## Testing
<!-- How was this tested? -->
- [ ] Unit tests added/updated
- [ ] Manual testing: <describe>
- [ ] No tests needed (explain why)

## Deployment Notes
<!-- Anything the reviewer or merger needs to know -->
- Requires env var: 
- Run migration: 
- Deploy order: 

## Screenshots / Logs
<!-- If applicable -->

## Related Issues
Closes #
```

Fill in every section. If a section doesn't apply, say "N/A" — don't delete it.

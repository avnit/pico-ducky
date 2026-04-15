---
name: session-summary
description: >
  Produces a compact session state document for handing off context to a new
  Claude Code session or another agent. Use when session is getting long, user
  says "summarize what we've done", "context handoff", "new session", or
  "save our progress". Creates a HANDOFF.md file.
---

# Session Summary / Handoff

Generate a structured handoff document and save it as `HANDOFF.md`
in the current working directory.

## Handoff Template

```markdown
# Session Handoff — {DATE}

## Objective
<!-- What were we trying to accomplish? -->

## What Was Done
<!-- Chronological list of completed actions -->
1. 
2. 

## Current State
<!-- Exact state of the system right now -->
- Files modified: 
- Commands run: 
- Services/processes affected: 

## What's Left
<!-- Ordered list of remaining tasks -->
- [ ] 
- [ ] 

## Blockers / Open Questions
<!-- What we got stuck on or need to decide -->
- 

## Key Decisions Made
<!-- Important choices and their rationale -->
- Decision: | Rationale:

## Exact Context to Resume
<!-- The single most important thing the next session needs to know first -->

## Commands to Run Next
<!-- Copy-paste ready commands to pick up where we left off -->
```bash
# First thing to run:

```
```

## Instructions

1. Review the full conversation history
2. Fill in every section — don't skip any
3. Save as `HANDOFF.md` in the project root
4. Confirm the file was written: `cat HANDOFF.md`

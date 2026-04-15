#Requires -Version 5.1
<#
.SYNOPSIS
    Install Claude Code Skills for Windows 11
    
.DESCRIPTION
    Creates ~/.claude/skills/ and installs curated SKILL.md packages
    tuned for a GCP Security / Cloud Engineer workflow.
    
    Skills installed:
      1. gcp-security-review    - IAM, VPC SC, SCC, Cloud Run audits
      2. terraform-gcp-security - Terraform GCP security linting
      3. code-reviewer          - General bug + security code review
      4. git-commit-writer      - Conventional commit messages
      5. pr-description-writer  - PR descriptions from branch diff
      6. env-doctor             - Diagnoses broken dev environments
      7. explain-code           - Visual diagrams + analogies
      8. session-summary        - Compact session state for handoff

.NOTES
    Run as your normal user — no admin required.
    Claude Code must be installed: npm install -g @anthropic-ai/claude-code
#>

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
$SkillsRoot = Join-Path $env:USERPROFILE ".claude\skills"
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
function Write-Step {
    param([string]$Msg)
    Write-Host "`n  ▶ $Msg" -ForegroundColor Cyan
}

function Write-OK {
    param([string]$Msg)
    Write-Host "    ✓ $Msg" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Msg)
    Write-Host "    ⊘ $Msg (already exists — skipping)" -ForegroundColor Yellow
}

function New-Skill {
    param(
        [string]$Name,
        [string]$Content
    )
    $dir = Join-Path $SkillsRoot $Name
    if (Test-Path $dir) {
        Write-Skip $Name
        return
    }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $Content | Set-Content -Path (Join-Path $dir "SKILL.md") -Encoding UTF8
    Write-OK "Installed: $Name"
}

# ─────────────────────────────────────────────────────────────────────────────
# PREFLIGHT
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "   Claude Code Skills Installer — GCP Security Edition " -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta

Write-Step "Checking Claude Code installation..."
try {
    $claudeVersion = & claude --version 2>&1
    Write-OK "Found Claude Code: $claudeVersion"
} catch {
    Write-Host "`n  ✗ Claude Code not found. Install it first:" -ForegroundColor Red
    Write-Host "    npm install -g @anthropic-ai/claude-code" -ForegroundColor White
    exit 1
}

Write-Step "Creating skills directory: $SkillsRoot"
if (-not (Test-Path $SkillsRoot)) {
    New-Item -ItemType Directory -Path $SkillsRoot -Force | Out-Null
    Write-OK "Created $SkillsRoot"
} else {
    Write-OK "Already exists: $SkillsRoot"
}


# ═════════════════════════════════════════════════════════════════════════════
# SKILL 1 — GCP Security Review
# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Installing skill: gcp-security-review"
New-Skill -Name "gcp-security-review" -Content @'
---
name: gcp-security-review
description: >
  Reviews GCP configurations, Terraform, and IAM policies for security
  misconfigurations. Use when auditing GCP resources, IAM bindings, VPC SC
  perimeters, SCC findings, Cloud Run security, or any Google Cloud
  infrastructure code. Auto-invokes when user says "review", "audit",
  "check security", "IAM", "VPC SC", or "SCC" in context of GCP.
---

# GCP Security Review

You are conducting a structured GCP security review. Follow this playbook:

## 1. IAM Analysis
- Flag `allUsers` or `allAuthenticatedUsers` bindings — always critical
- Flag primitive roles: `roles/owner`, `roles/editor`, `roles/viewer`
- Check for cross-project service account impersonation
- Validate `iam.disableServiceAccountKeyCreation` org policy
- Check for `iam.allowedPolicyMemberDomains` org policy enforcement
- Look for service accounts with excessive scopes

## 2. VPC Service Controls
- Validate service perimeter boundaries — are all critical APIs included?
- Check ingress/egress rules for overly broad `*` sources
- Look for `ENFORCE` vs `DRY_RUN` mode — DRY_RUN means policies aren't enforced
- Check access level conditions (IP, device policy, identity)
- Verify BigQuery, GCS, and Secret Manager are in perimeter if used

## 3. Cloud Run Security
- Verify IAP is enabled or `--no-allow-unauthenticated` is set
- Check Workforce Identity Federation pool and provider configuration
- Validate `principalSet://` bindings, not legacy `serviceAccount:` format
- Check ingress settings: `internal`, `internal-and-cloud-load-balancing`, or `all`
- Verify Cloud Run service identity has least-privilege SA

## 4. SCC Enterprise Findings
- Map findings to CIS GCP Benchmark v2.0 controls
- Prioritize: CRITICAL → HIGH → MEDIUM
- Group by resource type: Project > SA > Network > Storage
- Flag misconfigurations vs active threats separately

## 5. Terraform / IaC Review
- Flag `google_iam_binding` with wildcard members
- Check `google_storage_bucket` for `uniform_bucket_level_access = false`
- Check `google_compute_firewall` for `0.0.0.0/0` ingress on SSH/RDP
- Validate `google_project_service` — unnecessary APIs enabled = attack surface
- Check `depends_on` chains for SA key creation patterns

## Output Format

Always produce a findings table:

| # | Resource | Finding | Severity | CIS Control | Remediation |
|---|----------|---------|----------|-------------|-------------|
| 1 | ... | ... | CRITICAL/HIGH/MED/LOW | ... | ... |

Then a summary: Total findings by severity, top 3 priority actions.
'@


# ═════════════════════════════════════════════════════════════════════════════
# SKILL 2 — Terraform GCP Security Linter
# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Installing skill: terraform-gcp-security"
New-Skill -Name "terraform-gcp-security" -Content @'
---
name: terraform-gcp-security
description: >
  Lints and reviews Terraform HCL files for GCP security issues. Auto-invokes
  when working with .tf files, `terraform plan` output, or when user asks to
  "check terraform", "review tf", or "secure my infra". Covers IAM, networking,
  storage, compute, and org policies.
---

# Terraform GCP Security Linter

You are reviewing Terraform for GCP security misconfigurations.

## High-Priority Checks

### IAM
```
CRITICAL: member = "allUsers" or "allAuthenticatedUsers"
CRITICAL: role = "roles/owner" on non-breakglass accounts
HIGH:     role = "roles/editor" on service accounts
HIGH:     google_service_account_key resource (key rotation bypass)
MED:      Missing condition blocks on sensitive role bindings
```

### Networking
```
CRITICAL: google_compute_firewall — source_ranges = ["0.0.0.0/0"] with ports 22/3389
HIGH:     google_compute_instance — no shielded VM config
HIGH:     google_compute_subnetwork — private_ip_google_access = false
MED:      google_compute_network — no VPC flow logs
```

### Storage & Data
```
CRITICAL: google_storage_bucket — uniform_bucket_level_access = false
CRITICAL: google_storage_bucket — public_access_prevention = "inherited" 
HIGH:     google_bigquery_dataset — access block with allUsers
HIGH:     google_sql_database_instance — no backup_configuration
MED:      google_storage_bucket — no versioning for sensitive buckets
```

### Secrets & Keys
```
CRITICAL: Hardcoded credentials in variable defaults or locals
HIGH:     google_kms_crypto_key — rotation_period not set
HIGH:     sensitive = false on outputs containing secret values
```

## Output Format

For each finding:
```
[SEVERITY] Resource: <resource_type>.<name>
  Line: <approximate line or block>
  Issue: <what's wrong>
  Fix:   <exact Terraform snippet to remediate>
```

Then: tfsec / checkov equivalent control IDs where applicable.
'@


# ═════════════════════════════════════════════════════════════════════════════
# SKILL 3 — Code Reviewer
# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Installing skill: code-reviewer"
New-Skill -Name "code-reviewer" -Content @'
---
name: code-reviewer
description: >
  Performs a thorough code review covering bugs, security vulnerabilities,
  performance, and best practices. Use when asked to "review", "check",
  "audit code", or "look at this file". Works on any language.
---

# Code Review

Perform a structured code review across these dimensions:

## Security
- Injection vulnerabilities (SQL, command, LDAP, XPath)
- Authentication / authorization bypass
- Secrets or credentials in code
- Insecure deserialization
- Path traversal / directory traversal
- Dependency vulnerabilities (flag any `import` worth checking)

## Correctness
- Logic errors, off-by-one bugs
- Null/undefined dereferences
- Race conditions or thread safety issues
- Error handling gaps — uncaught exceptions, swallowed errors
- Edge cases (empty input, max values, encoding)

## Performance
- N+1 query patterns
- Unnecessary loops inside loops
- Missing indexes on filtered fields
- Memory leaks (unclosed resources, large allocations in loops)

## Maintainability
- Functions > 50 lines without clear justification
- Magic numbers without named constants
- Duplication that should be extracted
- Naming that doesn't reflect purpose

## Output Format

Group findings by severity: CRITICAL > HIGH > MED > LOW > NITPICK

For each finding:
```
[SEVERITY] Line XX: <one-line description>
  Why: <why this is a problem>
  Fix: <code snippet or specific change>
```

End with: Overall assessment (1-5) and top 3 priority fixes.
'@


# ═════════════════════════════════════════════════════════════════════════════
# SKILL 4 — Git Commit Writer
# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Installing skill: git-commit-writer"
New-Skill -Name "git-commit-writer" -Content @'
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
'@


# ═════════════════════════════════════════════════════════════════════════════
# SKILL 5 — PR Description Writer
# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Installing skill: pr-description-writer"
New-Skill -Name "pr-description-writer" -Content @'
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
'@


# ═════════════════════════════════════════════════════════════════════════════
# SKILL 6 — Env Doctor
# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Installing skill: env-doctor"
New-Skill -Name "env-doctor" -Content @'
---
name: env-doctor
description: >
  Diagnoses why a project, service, or dev environment won't start or is broken.
  Auto-invokes when user says "it's not working", "won't start", "broken",
  "error starting", or describes a startup failure. Runs systematic checks.
---

# Env Doctor

Systematically diagnose why the environment is broken.

## Diagnostic Runbook

### 1. Collect error output
```bash
# Get the actual error — don't guess
<run the failing command> 2>&1 | tail -50
```

### 2. Check dependencies
```bash
# Node
node --version && npm --version
cat package.json | grep -E '"engines|"node'

# Python
python --version
pip list | grep -E 'requirement|conflict'

# Go
go version
go mod verify
```

### 3. Check environment variables
```bash
# What's set vs what's needed
cat .env.example | grep -v '^#' | grep '='
printenv | grep -E 'PORT|HOST|DB|API|SECRET|KEY|URL'
```

### 4. Check ports and processes
```bash
# Windows
netstat -ano | findstr LISTENING
tasklist | findstr <process>

# What's blocking the port?
netstat -ano | findstr :8080
```

### 5. Check file permissions and paths
```bash
# Does the config file exist?
ls -la .env config/ *.json 2>&1

# Is the binary in PATH?
where <command>  # Windows
which <command>  # Unix
```

### 6. Check service dependencies
```bash
# Is the DB up?
# Is Redis up?
# Is the API it depends on reachable?
curl -s -o /dev/null -w "%{http_code}" <dependency-url>
```

## Output

Report findings as:
```
PROBLEM: <what's broken>
CAUSE:   <why it's broken>
FIX:     <exact command or change to fix it>
```

Then verify the fix worked by re-running the original command.
'@


# ═════════════════════════════════════════════════════════════════════════════
# SKILL 7 — Explain Code
# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Installing skill: explain-code"
New-Skill -Name "explain-code" -Content @'
---
name: explain-code
description: >
  Explains code with visual ASCII diagrams and real-world analogies. Use when
  explaining how code works, teaching a codebase, or when user asks "how does
  this work?", "walk me through", "explain this", or "what does this do?".
---

# Explain Code

When explaining code, always include all four of these:

## 1. Real-World Analogy
Compare the code to something from everyday life. Make it memorable.
Example: "A middleware stack is like a series of security checkpoints at an
airport — each one can inspect your bag, add a stamp, or turn you away."

## 2. ASCII Diagram
Draw the flow, structure, or relationships visually:
```
Request → [AuthMiddleware] → [RateLimiter] → [Handler] → Response
               ↓ fail              ↓ fail
             401                  429
```

## 3. Step-by-Step Walkthrough
Narrate exactly what happens, in execution order. Reference actual line
numbers or function names from the code. Use plain English.

## 4. The Gotcha
Identify one thing that commonly trips people up, a non-obvious
behavior, or a footgun in this code. Label it clearly:

> ⚠️ **Gotcha**: ...

## Style
- Conversational, not academic
- For complex concepts, use multiple analogies
- If the code has a bug or smell, mention it briefly at the end
'@


# ═════════════════════════════════════════════════════════════════════════════
# SKILL 8 — Session Summary / Handoff
# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Installing skill: session-summary"
New-Skill -Name "session-summary" -Content @'
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
'@


# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "   Installation Complete!                               " -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Skills installed to: $SkillsRoot" -ForegroundColor White
Write-Host ""
Write-Host "  Installed skills:" -ForegroundColor White

$skills = Get-ChildItem -Path $SkillsRoot -Directory
foreach ($s in $skills) {
    Write-Host "    /$($s.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "  How to use:" -ForegroundColor Yellow
Write-Host "    Invoke manually:  /gcp-security-review ./terraform/" -ForegroundColor Gray
Write-Host "    Auto-triggered:   just describe what you want, Claude picks the skill" -ForegroundColor Gray
Write-Host "    Disable a skill:  rename folder to _skillname" -ForegroundColor Gray
Write-Host "    Update a skill:   edit the SKILL.md file directly" -ForegroundColor Gray
Write-Host ""
Write-Host "  Browse more skills:" -ForegroundColor Yellow
Write-Host "    https://agensi.io/skills" -ForegroundColor Gray
Write-Host "    https://github.com/hesreallyhim/awesome-claude-code" -ForegroundColor Gray
Write-Host ""
Write-Host "  Start a new Claude Code session to pick up all skills." -ForegroundColor Cyan
Write-Host ""

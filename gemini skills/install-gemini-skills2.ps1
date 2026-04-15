#Requires -Version 5.1
<#
.SYNOPSIS
    Install Gemini Code Skills from awesome-gemini-code and curated repos

.DESCRIPTION
    Clones top skill repos listed in hesreallyhim/awesome-gemini-code and
    installs them into ~/.gemini/skills/ with namespace prefixes.
    Also installs custom GCP security skills.

    Repos installed:
      acc/    - awesome-gemini-code commands (evaluate-repository)
      tob/    - Trail of Bits security (CodeQL, Semgrep, audit workflows)
      sp/     - Superpowers by Jesse Vincent (SDLC engineering)
      devops/ - cc-devops-skills by akin-ozer (IaC, cloud, deploy)
      ecc/    - Everything Gemini Code by affaan-m (comprehensive)
      taches/ - TACHES by glittercowboy (meta-skills, auditor, hooks)
      gcp/    - Custom GCP security (IAM, VPC SC, SCC, Terraform)

.NOTES
    Requires: git in PATH
    Run:      powershell -ExecutionPolicy Bypass -File .\install-gemini-skills.ps1
    No admin required.
#>

$SkillsRoot  = Join-Path $env:USERPROFILE ".gemini\skills"
$CommandsDir = Join-Path $env:USERPROFILE ".gemini\commands"
$TempRoot    = Join-Path $env:TEMP "gemini-skills-$([System.IO.Path]::GetRandomFileName())"
$ErrorActionPreference = "Stop"

$Repos = @(
    @("acc",    "https://github.com/hesreallyhim/awesome-gemini-code",  "Awesome Gemini Code"),
    @("tob",    "https://github.com/trailofbits/skills",                "Trail of Bits - Security/Audit/CodeQL"),
    @("sp",     "https://github.com/obra/superpowers",                  "Superpowers - Core SDLC engineering"),
    @("devops", "https://github.com/akin-ozer/cc-devops-skills",        "DevOps/IaC - Cloud, Terraform, deploy"),
    @("ecc",    "https://github.com/affaan-m/everything-gemini-code",   "Everything Gemini Code - Comprehensive"),
    @("taches", "https://github.com/glittercowboy/taches-cc-resources", "TACHES - Meta-skills and auditors")
)

function Write-Banner {
    param([string]$Text)
    $line = "=" * 58
    Write-Host ""
    Write-Host $line -ForegroundColor Magenta
    Write-Host "  $Text" -ForegroundColor Magenta
    Write-Host $line -ForegroundColor Magenta
}
function Write-Step { param([string]$M); Write-Host "`n  >> $M" -ForegroundColor Cyan }
function Write-OK   { param([string]$M); Write-Host "     [OK]   $M" -ForegroundColor Green }
function Write-Skip { param([string]$M); Write-Host "     [SKIP] $M" -ForegroundColor Yellow }
function Write-Warn { param([string]$M); Write-Host "     [WARN] $M" -ForegroundColor DarkYellow }
function Write-Fail { param([string]$M); Write-Host "     [FAIL] $M" -ForegroundColor Red }

function Install-SkillDir {
    param([string]$SourceDir, [string]$DestName)
    $dest = Join-Path $SkillsRoot $DestName
    if (Test-Path $dest) { Write-Skip $DestName; return }
    Copy-Item -Recurse -Path $SourceDir -Destination $dest -Force
    Write-OK "skill: /$DestName"
}

function Install-CommandAsSkill {
    param([string]$SourceFile, [string]$DestName)
    $dest = Join-Path $SkillsRoot $DestName
    if (Test-Path $dest) { Write-Skip $DestName; return }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $content = Get-Content $SourceFile -Raw -Encoding UTF8
    if ($content -notmatch "^---") {
        $stem   = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile)
        $header = "---`nname: $DestName`ndescription: Slash command - $stem`n---`n`n"
        $content = $header + $content
    }
    [System.IO.File]::WriteAllText((Join-Path $dest "SKILL.md"), $content, [System.Text.Encoding]::UTF8)
    Write-OK "command->skill: /$DestName"
}

function Process-Repo {
    param([string]$Prefix, [string]$CloneDir)
    $installed = 0

    # Pattern 1: any SKILL.md anywhere in repo (new skill format)
    $skillDirs = Get-ChildItem -Path $CloneDir -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty DirectoryName | Sort-Object -Unique
    foreach ($sd in $skillDirs) {
        $name = "$Prefix-" + (Split-Path $sd -Leaf)
        Install-SkillDir -SourceDir $sd -DestName $name
        $installed++
    }

    # Pattern 2: .gemini/commands/*.md (old slash-command format)
    $cmdDir = Join-Path $CloneDir ".gemini\commands"
    if (Test-Path $cmdDir) {
        Get-ChildItem -Path $cmdDir -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
            $name = "$Prefix-$($_.BaseName)"
            if (-not (Test-Path (Join-Path $SkillsRoot $name))) {
                Install-CommandAsSkill -SourceFile $_.FullName -DestName $name
                $installed++
            }
        }
    }

    # Pattern 3: Root-level *.md files (some repos use this)
    if ($installed -eq 0) {
        $skip = @("README.md","CHANGELOG.md","LICENSE.md","CONTRIBUTING.md","SECURITY.md")
        Get-ChildItem -Path $CloneDir -MaxDepth 1 -Filter "*.md" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notin $skip } |
            ForEach-Object {
                $name = "$Prefix-$($_.BaseName)"
                Install-CommandAsSkill -SourceFile $_.FullName -DestName $name
                $installed++
            }
    }

    if ($installed -eq 0) {
        Write-Warn "No skills or commands found in $Prefix (repo structure may have changed)"
    }
    return $installed
}

# -----------------------------------------------------------------------
# PREFLIGHT
# -----------------------------------------------------------------------
Write-Banner "Gemini Code Skills Installer - awesome-gemini-code Edition"

Write-Step "Checking prerequisites..."

try {
    $cv = & gemini --version 2>&1
    Write-OK "Gemini Code: $cv"
} catch {
    Write-Fail "Gemini Code not found - install: npm install -g @anthropic-ai/gemini-code"
    exit 1
}

try {
    $gv = & git --version 2>&1
    Write-OK "Git: $gv"
} catch {
    Write-Fail "Git not found - install from https://git-scm.com/download/win"
    exit 1
}

foreach ($d in @($SkillsRoot, $CommandsDir, $TempRoot)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-OK "Created: $d"
    }
}

# -----------------------------------------------------------------------
# CLONE AND INSTALL REPOS
# -----------------------------------------------------------------------
$totalInstalled = 0
$failed = @()

foreach ($repo in $Repos) {
    $prefix = $repo[0]
    $url    = $repo[1]
    $desc   = $repo[2]

    Write-Step "[$prefix] $desc"
    Write-Host "        $url" -ForegroundColor Gray

    $cloneDir = Join-Path $TempRoot $prefix
    try {
        $gitOut = & git clone --depth 1 --quiet $url $cloneDir 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git clone failed: $gitOut" }
        Write-OK "Cloned"
        $n = Process-Repo -Prefix $prefix -CloneDir $cloneDir
        $totalInstalled += $n
    } catch {
        Write-Fail "Failed: $_"
        $failed += "$prefix ($url)"
    }
}

# -----------------------------------------------------------------------
# CUSTOM GCP SECURITY SKILLS
# -----------------------------------------------------------------------
Write-Step "Installing custom GCP security skills..."

function New-GcpSkill {
    param([string]$Name, [string]$Content)
    $dir = Join-Path $SkillsRoot $Name
    if (Test-Path $dir) { Write-Skip $Name; return }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $dir "SKILL.md"), $Content, [System.Text.Encoding]::UTF8)
    Write-OK "skill: /$Name"
    $script:totalInstalled++
}

New-GcpSkill -Name "gcp-iam-audit" -Content @"
---
name: gcp-iam-audit
description: >
  Audits GCP IAM policies for privilege escalation, primitive roles, allUsers
  bindings, and cross-project SA impersonation. Use when asked to audit IAM,
  check permissions, review service accounts, or any IAM/RBAC topic on GCP.
---

# GCP IAM Audit

## Step 1: Collect IAM Data
  gcloud projects get-iam-policy PROJECT_ID --format=json
  gcloud iam service-accounts list --project=PROJECT_ID
  gcloud asset search-all-iam-policies --scope=projects/PROJECT_ID

## Step 2: Critical Checks

CRITICAL - allUsers or allAuthenticatedUsers bindings:
  Immediate revocation. No legitimate use case in production.

CRITICAL - Primitive roles (owner/editor/viewer) on service accounts:
  Replace with fine-grained predefined or custom roles.

HIGH - Cross-project SA key impersonation:
  Check iam.serviceAccountTokenCreator across project boundaries.

HIGH - User-managed service account keys:
  Should not exist unless absolutely required. Use Workload Identity.

MED - Missing IAM conditions on sensitive bindings:
  Add resource-level or time-based conditions.

MED - Org policy violations:
  iam.disableServiceAccountKeyCreation should be enforced.
  iam.allowedPolicyMemberDomains should restrict to org domain.

## Output Format

| Member | Role | Resource | Risk | Action |
|--------|------|----------|------|--------|

Finish with: top 3 remediation commands in gcloud syntax, copy-paste ready.
"@

New-GcpSkill -Name "gcp-vpc-sc-review" -Content @"
---
name: gcp-vpc-sc-review
description: >
  Reviews VPC Service Controls: perimeters, access levels, ingress/egress
  rules, DRY_RUN vs ENFORCE mode. Use when working with VPC SC, service
  perimeters, access context manager, or API boundary controls in GCP.
---

# GCP VPC Service Controls Review

## Step 1: List Perimeters
  gcloud access-context-manager perimeters list --policy=POLICY_ID
  gcloud access-context-manager perimeters describe PERIMETER_NAME --policy=POLICY_ID

## Step 2: Key Checks

CRITICAL - DRY_RUN mode on production perimeters:
  enforced=false means nothing is actually blocked. Requires ENFORCE mode.

CRITICAL - Missing critical services in perimeter:
  Verify: bigquery.googleapis.com, storage.googleapis.com,
  secretmanager.googleapis.com, container.googleapis.com are included.

HIGH - Overly permissive ingress rules:
  source.accessLevels = * grants access from any identity. Lock to specific levels.

HIGH - Egress rules allowing writes to external projects:
  Check for toResources: * in egress policies.

MED - Access levels without device policy:
  IP-only levels can be bypassed. Add requireScreenLock, requireCorpOwned.

## Output Format

Perimeter: NAME | Mode: ENFORCE/DRY_RUN
  Services missing: [list]
  Ingress issues: [describe]
  Egress issues: [describe]
  Access level gaps: [describe]
"@

New-GcpSkill -Name "gcp-scc-triage" -Content @"
---
name: gcp-scc-triage
description: >
  Triages and prioritizes Security Command Center findings. Maps to CIS GCP
  Benchmark, groups by resource type, generates remediation priority list.
  Use when working with SCC, security findings, CSPM, or GCP compliance posture.
---

# GCP SCC Finding Triage

## Step 1: Pull Active Findings
  gcloud scc findings list ORGANIZATION_ID \
    --filter="state=ACTIVE AND (severity=CRITICAL OR severity=HIGH)" \
    --format=json

## Step 2: Triage Framework

Group findings by category:
  1. ACTIVE_THREATS     - Malware, cryptomining, exfiltration
  2. VULNERABILITIES    - Exposed services, unpatched, open ports
  3. MISCONFIGURATIONS  - IAM, storage, network config
  4. COMPLIANCE         - CIS/PCI/HIPAA control violations

Priority matrix:
  P0 = CRITICAL + ACTIVE_THREAT (immediate response, <4h)
  P1 = CRITICAL + MISCONFIGURATION or HIGH + ACTIVE_THREAT (<24h)
  P2 = HIGH + MISCONFIGURATION or MEDIUM + ACTIVE_THREAT (<72h)
  P3 = MEDIUM + MISCONFIGURATION, LOW anything (<2 weeks)

## CIS GCP Benchmark Sections
  1.x = IAM and access
  2.x = Logging and monitoring
  3.x = Networking
  4.x = VMs and compute
  5.x = Storage
  6.x = Cloud SQL
  7.x = BigQuery

## Output Format

| Priority | Finding | Resource | CIS Control | SLA | Remediation |
|----------|---------|----------|-------------|-----|-------------|
"@

New-GcpSkill -Name "terraform-gcp-security" -Content @"
---
name: terraform-gcp-security
description: >
  Lints Terraform HCL for GCP security misconfigurations. Auto-invokes when
  working with .tf files, terraform plan output, or requests to check terraform,
  review tf, or secure GCP infrastructure code.
---

# Terraform GCP Security Linter

## IAM
- CRITICAL: member includes allUsers or allAuthenticatedUsers
- CRITICAL: role = roles/owner on non-breakglass SA
- HIGH:     google_service_account_key resource present
- HIGH:     Missing condition blocks on sensitive bindings
- MED:      roles/editor on any service account

## Networking
- CRITICAL: google_compute_firewall source_ranges 0.0.0.0/0 on ports 22 or 3389
- HIGH:     google_compute_subnetwork private_ip_google_access = false
- HIGH:     google_compute_instance missing shielded_instance_config
- MED:      Missing VPC flow logs on subnets

## Storage
- CRITICAL: google_storage_bucket uniform_bucket_level_access = false
- CRITICAL: google_storage_bucket public_access_prevention = inherited
- HIGH:     google_bigquery_dataset access.role READER with allUsers
- HIGH:     google_sql_database_instance missing backup_configuration

## Secrets
- CRITICAL: Credentials hardcoded in variable default or locals
- HIGH:     google_kms_crypto_key missing rotation_period
- HIGH:     output sensitive = false on keys or tokens

## Output Format

  [SEVERITY] resource_type.name
    Issue: <description>
    Fix:   <terraform snippet>
    Refs:  tfsec GCP### / checkov CKV_GCP_##
"@

# -----------------------------------------------------------------------
# CLEANUP
# -----------------------------------------------------------------------
Write-Step "Cleaning up temp directory..."
try {
    Remove-Item -Recurse -Force -Path $TempRoot -ErrorAction SilentlyContinue
    Write-OK "Removed $TempRoot"
} catch {
    Write-Warn "Could not auto-remove $TempRoot - safe to delete manually"
}

# -----------------------------------------------------------------------
# SUMMARY
# -----------------------------------------------------------------------
Write-Banner "Installation Complete"
Write-Host ""
Write-Host "  Skills root:  $SkillsRoot" -ForegroundColor White
Write-Host "  Total skills: $totalInstalled installed this run" -ForegroundColor White
Write-Host ""

Write-Host "  All installed skills:" -ForegroundColor Yellow
$skills = Get-ChildItem -Path $SkillsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name
foreach ($s in $skills) {
    $pfx = ($s.Name -split "-")[0]
    $color = switch ($pfx) {
        "tob"    { "Red" }
        "gcp"    { "Cyan" }
        "terraform" { "Cyan" }
        "devops" { "Green" }
        "sp"     { "Magenta" }
        "acc"    { "White" }
        "ecc"    { "Yellow" }
        "taches" { "DarkYellow" }
        default  { "Gray" }
    }
    Write-Host "    /$($s.Name)" -ForegroundColor $color
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "  Failed repos (check network/git):" -ForegroundColor Red
    foreach ($f in $failed) { Write-Host "    - $f" -ForegroundColor Red }
}

Write-Host ""
Write-Host "  Prefix legend:" -ForegroundColor Yellow
Write-Host "    acc-    = awesome-gemini-code commands" -ForegroundColor White
Write-Host "    tob-    = Trail of Bits security" -ForegroundColor Red
Write-Host "    sp-     = Superpowers SDLC skills" -ForegroundColor Magenta
Write-Host "    devops- = DevOps/IaC cloud skills" -ForegroundColor Green
Write-Host "    ecc-    = Everything Gemini Code" -ForegroundColor Yellow
Write-Host "    taches- = Meta-skills and auditors" -ForegroundColor DarkYellow
Write-Host "    gcp-    = Custom GCP security skills" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Quick start:" -ForegroundColor Yellow
Write-Host "    /gcp-iam-audit          - audit IAM policies" -ForegroundColor Gray
Write-Host "    /gcp-vpc-sc-review      - review VPC SC perimeters" -ForegroundColor Gray
Write-Host "    /gcp-scc-triage         - triage SCC findings" -ForegroundColor Gray
Write-Host "    /terraform-gcp-security - lint Terraform" -ForegroundColor Gray
Write-Host "    /tob-<name>             - Trail of Bits security skills" -ForegroundColor Gray
Write-Host ""
Write-Host "  To update: re-run script (existing skills are skipped)" -ForegroundColor Gray
Write-Host "  Start a new Gemini Code session to activate all skills." -ForegroundColor Cyan
Write-Host ""


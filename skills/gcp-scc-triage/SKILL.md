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
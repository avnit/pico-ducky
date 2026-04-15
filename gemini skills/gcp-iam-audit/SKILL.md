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
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

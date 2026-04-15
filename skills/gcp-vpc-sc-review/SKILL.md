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
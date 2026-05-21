#!/usr/bin/env bash
set -euo pipefail
 
echo "=== Plan Validation ==="
echo ""

trap 'rm -f tfplan plan.json' EXIT

# Generate plan in JSON format
terraform plan -out=tfplan -input=false
terraform show -json tfplan > plan.json
 
# Count planned resources
TOTAL=$(jq '[.resource_changes[] | select(.change.actions | contains(["create"]))] | length' plan.json)
echo "Resources to create: $TOTAL"
 
# Verify expected resources exist in plan
EXPECTED_TYPES=("aws_s3_bucket" "aws_s3_bucket_versioning" "aws_s3_bucket_server_side_encryption_configuration" "aws_dynamodb_table")
ERRORS=0
 
echo ""
echo "Checking expected resource types..."
for rtype in "${EXPECTED_TYPES[@]}"; do
  FOUND=$(jq --arg t "$rtype" '[.resource_changes[] | select(.type == $t)] | length' plan.json)
  if [ "$FOUND" -eq 0 ]; then
    echo "  FAIL: Expected resource type '$rtype' not in plan"
    ERRORS=$((ERRORS + 1))
  else
    echo "  PASS: $rtype ($FOUND instance(s))"
  fi
done
 
# Check no resources are being destroyed
DESTROYS=$(jq '[.resource_changes[] | select(.change.actions | contains(["delete"]))] | length' plan.json)
echo ""
echo "Checking for unexpected destroys..."
if [ "$DESTROYS" -gt 0 ]; then
  echo "  WARN: $DESTROYS resource(s) will be destroyed"
  jq -r '.resource_changes[] | select(.change.actions | contains(["delete"])) | "  - \(.address)"' plan.json
else
  echo "  PASS: No resources will be destroyed"
fi
 
echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS expected resource(s) missing from plan"
  exit 1
else
  echo "PASSED: Plan contains all expected resources"
  exit 0
fi
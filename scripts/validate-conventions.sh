#!/usr/bin/env bash
set -euo pipefail

ERRORS=0

echo "=== Convention Validation ==="
echo ""

# --- Check 1: Naming convention ---
echo "Checking naming conventions..."

while IFS= read -r line; do
  [ -z "$line" ] && continue
  file=$(echo "$line" | awk -F: '{print $1}')
  lineno=$(echo "$line" | awk -F: '{print $2}')
  content=$(echo "$line" | awk -F: '{for(i=3;i<=NF;i++) printf "%s%s",$i,(i<NF?":":""); print ""}')
  resource_name=$(echo "$content" | sed -E 's/.*resource[[:space:]]+"[^"]+"+[[:space:]]+"([^"]+)".*/\1/')

  if [[ ! "$resource_name" =~ ^[a-z][a-z0-9_]+$ ]]; then
    echo "  FAIL: $file:$lineno — resource name '$resource_name' must be lowercase with underscores"
    ERRORS=$((ERRORS + 1))
  fi
done < <(grep -n 'resource "' *.tf | grep -v '#' || true)

if [ "$ERRORS" -eq 0 ]; then
  echo "  PASS: All resource names follow conventions"
fi

# --- Check 2: Required tags ---
echo ""
echo "Checking required tags..."
REQUIRED_TAGS=("Name" "Environment" "ManagedBy")

for tag in "${REQUIRED_TAGS[@]}"; do
  TAGGED_RESOURCES=$(grep -l 'resource "aws_' *.tf 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")
  TAG_PRESENT=$(grep -rl "[[:space:]]$tag[[:space:]]" *.tf 2>/dev/null | wc -l | tr -d '[:space:]' || echo "0")

  if [ "$TAG_PRESENT" -eq 0 ] && [ "$TAGGED_RESOURCES" -gt 0 ]; then
    echo "  FAIL: Required tag '$tag' not found in any resource"
    ERRORS=$((ERRORS + 1))
  else
    echo "  PASS: Tag '$tag' found"
  fi
done

# --- Check 3: Variable descriptions ---
echo ""
echo "Checking variable descriptions..."
VAR_BLOCKS=$(grep -c '^variable "' variables.tf || true)
VAR_DESCS=$(grep -c 'description' variables.tf || true)

if [ "$VAR_DESCS" -lt "$VAR_BLOCKS" ]; then
  echo "  FAIL: $((VAR_BLOCKS - VAR_DESCS)) variable(s) missing descriptions"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: All $VAR_BLOCKS variables have descriptions"
fi

# --- Check 4: No hardcoded regions ---
echo ""
echo "Checking for hardcoded AWS regions..."
HARDCODED=$(grep -nE 'region[[:space:]]*=[[:space:]]*"[a-z]{2}-[a-z]+-[0-9]"' *.tf | grep -v 'var\.' | grep -v '#' || true)

if [ -n "$HARDCODED" ]; then
  echo "  FAIL: Hardcoded region found:"
  echo "  $HARDCODED"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: No hardcoded regions"
fi

# --- Summary ---
echo ""
echo "=== Results ==="
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS convention violation(s) found"
  exit 1
else
  echo "PASSED: All convention checks passed"
  exit 0
fi

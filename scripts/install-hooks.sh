#!/usr/bin/env bash
set -euo pipefail
 
REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.git/hooks"
mkdir -p "$HOOKS_DIR"
 
cat > "$HOOKS_DIR/pre-commit" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
 
echo "Running pre-commit checks..."
 
# Check Terraform formatting
echo "  Checking terraform fmt..."
if ! terraform fmt -check -recursive > /dev/null 2>&1; then
  echo "  FAIL: Terraform files need formatting. Run: terraform fmt -recursive"
  exit 1
fi
 
# Validate Terraform
echo "  Running terraform validate..."
if ! terraform validate > /dev/null 2>&1; then
  echo "  FAIL: Terraform validation failed. Run: terraform validate"
  exit 1
fi
 
# Run convention checks
echo "  Running convention checks..."
if ! ./scripts/validate-conventions.sh > /dev/null 2>&1; then
  echo "  FAIL: Convention checks failed. Run: ./scripts/validate-conventions.sh"
  exit 1
fi
 
echo "All pre-commit checks passed!"
HOOK
 
chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$REPO_ROOT/scripts/validate-conventions.sh"
echo "Pre-commit hook installed successfully."
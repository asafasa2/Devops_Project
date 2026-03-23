#!/bin/bash
# Minimal Jenkinsfile declarative syntax checker and simulator.
# Usage: run-jenkinsfile <Jenkinsfile>
#
# Validates that the Jenkinsfile has:
#   - pipeline { } block
#   - agent { } or agent any
#   - stages { } block
#   - At least one stage('...') { steps { } } block
# Then simulates running each stage.

set -euo pipefail

JENKINSFILE="${1:-}"

if [ -z "$JENKINSFILE" ] || [ ! -f "$JENKINSFILE" ]; then
    echo "Usage: run-jenkinsfile <Jenkinsfile>"
    exit 1
fi

CONTENT=$(cat "$JENKINSFILE")
ERRORS=0

echo "=== Jenkinsfile Validator ==="
echo "File: $JENKINSFILE"
echo ""

# Check pipeline block
if ! echo "$CONTENT" | grep -q 'pipeline\s*{'; then
    echo "ERROR: Missing 'pipeline { }' block"
    ERRORS=$((ERRORS+1))
fi

# Check agent directive
if ! echo "$CONTENT" | grep -qE 'agent\s+(any|none|\{)'; then
    echo "ERROR: Missing 'agent' directive. Use: agent any"
    ERRORS=$((ERRORS+1))
fi

# Check stages block
if ! echo "$CONTENT" | grep -q 'stages\s*{'; then
    echo "ERROR: Missing 'stages { }' block"
    ERRORS=$((ERRORS+1))
fi

# Check at least one stage
if ! echo "$CONTENT" | grep -q "stage("; then
    echo "ERROR: No stage() blocks found"
    ERRORS=$((ERRORS+1))
fi

# Check each stage has steps block
STAGE_COUNT=$(echo "$CONTENT" | grep -c "stage(" || true)
STEPS_COUNT=$(echo "$CONTENT" | grep -c "steps\s*{" || true)
if [ "$STEPS_COUNT" -lt "$STAGE_COUNT" ]; then
    echo "ERROR: Some stages are missing 'steps { }' blocks ($STAGE_COUNT stages, $STEPS_COUNT steps blocks)"
    ERRORS=$((ERRORS+1))
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "Syntax check FAILED with $ERRORS error(s)"
    exit 1
fi

echo "Syntax check PASSED"
echo ""
echo "=== Simulating Pipeline ==="

# Extract and simulate stage names
STAGES=$(echo "$CONTENT" | grep -oP "stage\('\K[^']+" || echo "$CONTENT" | grep -oP 'stage\("\K[^"]+')
for stage in $STAGES; do
    echo "[Pipeline] Stage '$stage'"
    echo "[Pipeline]   Running steps..."
    sleep 0.3
    echo "[Pipeline]   '$stage' completed"
done

echo ""
echo "=== Pipeline Result: SUCCESS ==="
exit 0

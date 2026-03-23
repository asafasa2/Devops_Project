#!/bin/bash
# Minimal pipeline runner for CI/CD labs.
# Usage: pipeline run <pipeline.yml>
#
# Pipeline YAML format:
#   stages:
#     - lint
#     - test
#     - build
#     - deploy
#   jobs:
#     lint:
#       script: |
#         echo "Linting..."
#     test:
#       script: |
#         echo "Testing..."

set -euo pipefail

CMD="${1:-}"
PIPELINE_FILE="${2:-}"

if [ "$CMD" != "run" ] || [ -z "$PIPELINE_FILE" ]; then
    echo "Usage: pipeline run <pipeline.yml>"
    exit 1
fi

if [ ! -f "$PIPELINE_FILE" ]; then
    echo "ERROR: Pipeline file not found: $PIPELINE_FILE"
    exit 1
fi

# Parse stages order
STAGES=$(python3 -c "
import sys, re
content = open('$PIPELINE_FILE').read()
m = re.search(r'stages:\s*\n((?:\s+-\s+\S+\n?)+)', content)
if not m:
    print('ERROR: no stages: section found', file=sys.stderr)
    sys.exit(1)
stages = [line.strip().lstrip('- ') for line in m.group(1).strip().split('\n') if line.strip()]
print('\n'.join(stages))
" 2>&1) || { echo "$STAGES"; exit 1; }

echo "Pipeline: $PIPELINE_FILE"
echo "Stages: $(echo "$STAGES" | tr '\n' ' ')"
echo "---"

FAILED=0
for stage in $STAGES; do
    echo ""
    echo "[STAGE] $stage"
    # Extract the script for this stage
    SCRIPT=$(python3 -c "
import sys, re, textwrap
content = open('$PIPELINE_FILE').read()
# Find jobs section for this stage
pattern = r'  $stage:\s*\n\s+script:\s*\|\s*\n((?:\s{8}.*\n?)*)'
m = re.search(pattern, content)
if not m:
    print('echo \"No script defined for stage $stage\"')
else:
    script = textwrap.dedent(m.group(1))
    print(script.strip())
" 2>/dev/null)

    if bash -c "$SCRIPT"; then
        echo "[STAGE] $stage — PASSED"
    else
        echo "[STAGE] $stage — FAILED"
        FAILED=1
        break
    fi
done

echo ""
if [ $FAILED -eq 0 ]; then
    echo "Pipeline SUCCEEDED"
    exit 0
else
    echo "Pipeline FAILED"
    exit 1
fi

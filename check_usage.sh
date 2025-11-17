#!/bin/bash

# GPU usage monitoring script for all workstation pods
# Usage: bash check_usage.sh

set -e

echo "🎮 GPU Usage Monitor for All Workstation Pods"
echo "=============================================="
echo ""

# Define the pods based on the order in launch.sh
POD_SPECS=(
    "pod0-0" "pod1-0" "pod2-0" "pod3-0" "pod4-0" "pod5-0"
    "pod6-0" "pod6-1"
)

# Get all running GPU workstation pods
RUNNING_PODS=$(kubectl get pods -l app=gpu-workstation --field-selector=status.phase=Running -o custom-columns="NAME:.metadata.name" --no-headers 2>/dev/null | tr '\n' ' ')

if [ -z "$RUNNING_PODS" ]; then
    echo "❌ No running GPU workstation pods found"
    exit 1
fi

for POD_SPEC in "${POD_SPECS[@]}"; do
    # Derive the full pod name from the spec
    POD_NAME="${POD_SPEC}"

    # Check if this specific pod is in the list of running pods
    if [[ " ${RUNNING_PODS} " =~ " ${POD_NAME} " ]]; then
        echo "✅ $POD_NAME"
        echo "----------------------------------------"
        
        # Get GPU usage
        if kubectl exec "$POD_NAME" -- nvidia-smi 2>/dev/null; then
            echo ""
        else
            echo "  ⚠️  Could not query GPU status (nvidia-smi not available or pod terminating)"
        fi
        
        echo ""
    fi
done

echo "📊 Summary:"
echo "==========="
# Get all pods for the summary, not just running ones
ALL_PODS=$(kubectl get pods -l app=gpu-workstation --no-headers -o custom-columns="NAME:.metadata.name" 2>/dev/null)
TOTAL_PODS_COUNT=$(echo "$ALL_PODS" | wc -w)
RUNNING_PODS_COUNT=$(echo "$RUNNING_PODS" | wc -w)

TOTAL_GPUS=0
if [ -n "$ALL_PODS" ]; then
    for POD in $ALL_PODS; do
        GPU_COUNT=$(kubectl get pod $POD -o jsonpath='{.spec.containers[0].resources.requests.nvidia\.com/gpu}' 2>/dev/null || echo 0)
        TOTAL_GPUS=$((TOTAL_GPUS + GPU_COUNT))
    done
fi

echo "Total pods: $TOTAL_PODS_COUNT"
echo "Running pods: $RUNNING_PODS_COUNT"
echo "Total GPUs requested: $TOTAL_GPUS"
echo ""
echo "💡 To connect to a pod: bash connect.sh <pod_spec>"
echo "💡 Examples: bash connect.sh pod0-0, bash connect.sh pod6-1"

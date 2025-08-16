#!/bin/bash

# GPU usage monitoring script for all workstation pods
# Usage: bash check_usage.sh

set -e

echo "🎮 GPU Usage Monitor for All Workstation Pods"
echo "=============================================="
echo ""

# Get all GPU workstation pods
PODS=$(kubectl get pods -l app=gpu-workstation --no-headers -o custom-columns="NAME:.metadata.name" 2>/dev/null | tr '\n' ' ')

if [ -z "$PODS" ]; then
    echo "❌ No GPU workstation pods found"
    echo "Deploy some pods first with: bash launch.sh <node_idx> <ngpu>"
    exit 1
fi

# Sort pods by name for consistent output
PODS_SORTED=$(echo $PODS | tr ' ' '\n' | sort)

for POD in $PODS_SORTED; do
    echo "$POD"
    echo "----------------------------------------"
    
    # Check if pod is running
    POD_STATUS=$(kubectl get pod "$POD" -o jsonpath='{.status.phase}' 2>/dev/null)
    
    if [ "$POD_STATUS" = "Running" ]; then
        # Get GPU usage
        # if kubectl exec "$POD" -- nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null; then
        if kubectl exec "$POD" -- nvidia-smi  2>/dev/null; then
            echo ""
        else
            echo "  ⚠️  Could not query GPU status (nvidia-smi not available)"
        fi
    else
        echo "  ⚠️  Pod is not running (status: $POD_STATUS)"
    fi
    
    echo ""
done

echo "📊 Summary:"
echo "==========="
echo "Total pods: $(echo $PODS | wc -w)"
echo "Running pods: $(kubectl get pods -l app=gpu-workstation --no-headers | grep Running | wc -l)"
echo "Total GPUs: $(kubectl get pods -l app=gpu-workstation -o jsonpath='{.items[*].spec.containers[0].resources.requests.nvidia\.com/gpu}' | tr ' ' '\n' | awk '{sum+=$1} END {print sum}')"
echo ""
echo "💡 To connect to a pod: bash connect.sh aws<node>-<pod_num>"
echo "💡 Examples: bash connect.sh aws0-0, bash connect.sh aws4-1"
echo "💡 To launch new pods: bash launch.sh <node_idx> <ngpu>"

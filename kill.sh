#!/bin/bash

# Kill script for GPU workstation pods
# Usage: bash kill.sh <pod_spec>
# Example: bash kill.sh 0-0
# Example: bash kill.sh 6-1

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <pod_spec>"
    echo "Example: $0 0-0"
    echo "Example: $0 6-1"
    exit 1
fi

POD_SPEC=$1

# Parse pod_spec
if [[ ! $POD_SPEC =~ ^([0-9]+)-([0-9]+)$ ]]; then
    echo "Error: Invalid pod_spec format. Expected <node_idx>-<pod_idx>"
    exit 1
fi

NODE_IDX=${BASH_REMATCH[1]}
POD_IDX=${BASH_REMATCH[2]}

# Determine NGPU based on the deployment logic in deploy_all.sh
if [ $NODE_IDX -ge 0 ] && [ $NODE_IDX -le 5 ]; then
    NGPU=8
elif [ $NODE_IDX -ge 6 ] && [ $NODE_IDX -le 7 ]; then
    NGPU=4
else
    echo "Error: Invalid node_idx. No pods are deployed on node $NODE_IDX."
    exit 1
fi

POD_NAME="aws${NODE_IDX}-${POD_IDX}-${NGPU}gpus"

echo "🔍 Finding pod $POD_NAME..."

# Check if the pod exists before attempting to delete it
if ! kubectl get pod "$POD_NAME" >/dev/null 2>&1; then
    echo "❌ Pod $POD_NAME not found."
    exit 1
fi

echo "🗑️  Deleting pod $POD_NAME..."
kubectl delete pod "$POD_NAME" --force --grace-period=0

echo "✅ Pod $POD_NAME has been deleted."




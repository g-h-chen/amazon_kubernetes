#!/bin/bash

# Connect script for GPU workstation pods
# Usage: bash connect.sh <pod_identifier>

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <pod_identifier>"
    echo "Example: $0 pod0-0    # Connect to 8-GPU pod on node 0"
    echo "Example: $0 pod6-1    # Connect to second 4-GPU pod on node 6"
    echo ""
    echo "Pod naming convention:"
    echo "  pod{0,1,2,3,4,5}-0   # 8-GPU pods"
    echo "  pod6-0               # First 4-GPU pod"
    echo "  pod6-1               # Second 4-GPU pod"
    exit 1
fi

POD_IDENTIFIER=$1

# Parse the pod identifier
if [[ $POD_IDENTIFIER =~ ^pod([0-9]+)-([0-9]+)$ ]]; then
    NODE_IDX=${BASH_REMATCH[1]}
    POD_NUM=${BASH_REMATCH[2]}
else
    echo "Error: Invalid pod identifier format. Use 'pod<node>-<pod_num>'"
    echo "Example: pod0-0, pod6-1"
    exit 1
fi

# Determine pod name based on node and pod number
POD_NAME=$POD_IDENTIFIER
echo "🔗 Connecting to pod: ${POD_NAME}"

# Check if pod exists and is running
if ! kubectl get pod "$POD_NAME" >/dev/null 2>&1; then
    echo "❌ Error: Pod $POD_NAME not found"
    echo "Available pods:"
    kubectl get pods -l app=gpu-workstation
    exit 1
fi

POD_STATUS=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Error: Pod $POD_NAME is not running (status: $POD_STATUS)"
    exit 1
fi

echo "✅ Pod $POD_NAME is ready!"
echo "💡 Tip: Use 'nvidia-smi' to check GPU status"
echo "💡 Tip: Your conda env is in /home/efs/conda_envs/"
echo "💡 Tip: Use 'conda activate <env_name>' to switch conda environments"
echo "💡 Tip: Your data is in /home/efs/"
echo ""

# Connect to the pod
kubectl exec -it "$POD_NAME" -- /bin/bash

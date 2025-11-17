#!/bin/bash

# Batch deployment script for all GPU workstation pods
# Deploys 8 pods across 7 nodes: 6x8-GPU + 1x(2x4-GPU) = 56 GPUs total

set -e

echo "🚀 Batch Deployment: 7 Nodes, 8 Pods, 56 GPUs Total"
echo "======================================================"
echo ""

# Phase 1: Deploy 8-GPU pods on nodes 0-5
echo "📦 Phase 1: Deploying 8-GPU pods (Nodes 0-5)"
echo "----------------------------------------------"
for node in 0 1 2 3 4 5; do
    echo "Deploying pod${node}-0..."
    bash launch.sh ${node}-0 8
    echo ""
done

# Phase 2: Deploy two 4-GPU pods on node 6
echo "📦 Phase 2: Deploying two 4-GPU pods (Node 6)"
echo "---------------------------------------------------"
echo "Deploying pod6-0..."
bash launch.sh 6-0 4
echo ""
echo "Deploying pod6-1..."
bash launch.sh 6-1 4
echo ""

echo "🎉 All pods deployed successfully!"
echo ""
echo "📊 Check deployment status:"
echo "  bash check_usage.sh"
echo ""
echo "🔗 Connect to pods:"
echo "  bash connect.sh pod0-0    # 8-GPU pod on node 0"
echo "  bash connect.sh pod1-0    # 8-GPU pod on node 1"
echo "  bash connect.sh pod2-0    # 8-GPU pod on node 2"
echo "  bash connect.sh pod3-0    # 8-GPU pod on node 3"
echo "  bash connect.sh pod4-0    # 8-GPU pod on node 4"
echo "  bash connect.sh pod5-0    # 8-GPU pod on node 5"
echo "  bash connect.sh pod6-0    # First 4-GPU pod on node 6"
echo "  bash connect.sh pod6-1    # Second 4-GPU pod on node 6"
echo ""
echo "📋 Pod Summary:"
echo "  pod0-0: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  pod1-0: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  pod2-0: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  pod3-0: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  pod4-0: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  pod5-0: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  pod6-0: 4 GPUs (0,1,2,3)"
echo "  pod6-1: 4 GPUs (4,5,6,7)"
echo "  Total: 56 GPUs across 8 pods"

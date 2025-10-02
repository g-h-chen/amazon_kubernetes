#!/bin/bash

# Batch deployment script for all GPU workstation pods
# Deploys 10 pods across 8 nodes: 6x8-GPU + 2x(2x4-GPU) = 64 GPUs total

set -e

echo "🚀 Batch Deployment: 8 Nodes, 10 Pods, 64 GPUs Total"
echo "======================================================"
echo ""

# Phase 1: Deploy 8-GPU pods on nodes 0-5
echo "📦 Phase 1: Deploying 8-GPU pods (Nodes 0-5)"
echo "----------------------------------------------"
for node in 0 1 2 3 4 5; do
    echo "Deploying aws${node}-0-8gpus..."
    bash launch.sh ${node}-0 8
    echo ""
done

# Phase 2: Deploy first 4-GPU pods on nodes 6-7
echo "📦 Phase 2: Deploying first 4-GPU pods (Nodes 6-7)"
echo "---------------------------------------------------"
for node in 6 7; do
    echo "Deploying aws${node}-0-4gpus..."
    bash launch.sh ${node}-0 4
    echo ""
done

# Phase 3: Deploy second 4-GPU pods on nodes 6-7
echo "📦 Phase 3: Deploying second 4-GPU pods (Nodes 6-7)"
echo "----------------------------------------------------"
for node in 6 7; do
    echo "Deploying aws${node}-1-4gpus..."
    bash launch.sh ${node}-1 4
    echo ""
done

echo "🎉 All pods deployed successfully!"
echo ""
echo "📊 Check deployment status:"
echo "  bash check_usage.sh"
echo ""
echo "🔗 Connect to pods:"
echo "  bash connect.sh aws0-0    # 8-GPU pod on node 0"
echo "  bash connect.sh aws1-0    # 8-GPU pod on node 1"
echo "  bash connect.sh aws2-0    # 8-GPU pod on node 2"
echo "  bash connect.sh aws3-0    # 8-GPU pod on node 3"
echo "  bash connect.sh aws4-0    # 8-GPU pod on node 4"
echo "  bash connect.sh aws5-0    # 8-GPU pod on node 5"
echo "  bash connect.sh aws6-0    # First 4-GPU pod on node 6"
echo "  bash connect.sh aws6-1    # Second 4-GPU pod on node 6"
echo "  bash connect.sh aws7-0    # First 4-GPU pod on node 7"
echo "  bash connect.sh aws7-1    # Second 4-GPU pod on node 7"
echo ""
echo "📋 Pod Summary:"
echo "  aws0-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws1-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws2-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws3-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws4-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws5-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws6-0-4gpus: 4 GPUs (0,1,2,3)"
echo "  aws6-1-4gpus: 4 GPUs (4,5,6,7)"
echo "  aws7-0-4gpus: 4 GPUs (0,1,2,3)"
echo "  aws7-1-4gpus: 4 GPUs (4,5,6,7)"
echo "  Nodes 8, 9 are reserved."
echo "  Total: 64 GPUs across 10 pods"

#!/bin/bash

# Batch deployment script for all GPU workstation pods
# Deploys 8 pods across 6 nodes: 4x8-GPU + 4x4-GPU = 48 GPUs total

set -e

echo "🚀 Batch Deployment: 6 Nodes, 8 Pods, 48 GPUs Total"
echo "====================================================="
echo ""

# Phase 1: Deploy 8-GPU pods on nodes 0-3
echo "📦 Phase 1: Deploying 8-GPU pods (Nodes 0-3)"
echo "----------------------------------------------"
for node in 0 1 2 3; do
    echo "Deploying aws${node}-0-8gpus..."
    bash launch.sh $node 8
    echo ""
done

# Phase 2: Deploy first 4-GPU pod on nodes 4-5
echo "📦 Phase 2: Deploying first 4-GPU pods (Nodes 4-5)"
echo "---------------------------------------------------"
for node in 4 5; do
    echo "Deploying aws${node}-0-4gpus..."
    bash launch.sh $node 4
    echo ""
done

# Phase 3: Deploy second 4-GPU pod on nodes 4-5
echo "📦 Phase 3: Deploying second 4-GPU pods (Nodes 4-5)"
echo "----------------------------------------------------"
for node in 4 5; do
    echo "Deploying aws${node}-1-4gpus..."
    
    # Create second 4-GPU pod manually
    POD_NAME="aws${node}-1-4gpus"
    NODES=(
        "ip-172-31-129-163.us-west-2.compute.internal"
        "ip-172-31-130-216.us-west-2.compute.internal"
        "ip-172-31-131-175.us-west-2.compute.internal"
        "ip-172-31-137-252.us-west-2.compute.internal"
        "ip-172-31-138-171.us-west-2.compute.internal"
        "ip-172-31-138-243.us-west-2.compute.internal"
        "ip-172-31-141-194.us-west-2.compute.internal"
        "ip-172-31-150-162.us-west-2.compute.internal"
    )
    NODE_NAME=${NODES[$node]}
    
    # Create second 4-GPU pod YAML
    cat > pod_yamls/${POD_NAME}.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  labels:
    app: gpu-workstation
    node-idx: "${node}"
    gpu-count: "4"
spec:
  nodeSelector:
    kubernetes.io/hostname: "${NODE_NAME}"
  containers:
  - name: workstation
    image: hchen403/cuda128-miniconda:py312
    imagePullPolicy: Always
    command: ["/bin/bash"]
    args: ["-c", "sleep infinity"]
    resources:
      requests:
        memory: "500Gi"
        cpu: "45"
        nvidia.com/gpu: "4"
      limits:
        memory: "500Gi"
        cpu: "47"
        nvidia.com/gpu: "4"
    volumeMounts:
    - name: efs-storage
      mountPath: /home
    - name: dshm
      mountPath: /dev/shm
    env:
    - name: CUDA_VISIBLE_DEVICES
      value: "4,5,6,7"  # Second 4 GPUs
    - name: PYTHONPATH
      value: "/home/efs/connect_to_cluster"
    workingDir: /home/efs/
    tty: true
    stdin: true
  volumes:
  - name: efs-storage
    persistentVolumeClaim:
      claimName: fsx
  - name: dshm
    emptyDir:
      medium: Memory
      sizeLimit: 64Gi
  restartPolicy: Never
EOF

    echo "📝 Created pod manifest: pod_yamls/${POD_NAME}.yaml"
    
    # Delete existing pod if it exists
    if kubectl get pod "$POD_NAME" >/dev/null 2>&1; then
        echo "🗑️  Deleting existing pod $POD_NAME..."
        kubectl delete pod "$POD_NAME" --force --grace-period=0
        sleep 5
    fi
    
    # Deploy the pod
    echo "🚀 Deploying pod..."
    kubectl apply -f pod_yamls/${POD_NAME}.yaml
    
    echo "⏳ Waiting for pod to be ready..."
    kubectl wait --for=condition=ready pod/${POD_NAME} --timeout=300s
    
    echo "✅ Pod ${POD_NAME} is ready!"
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
echo "  bash connect.sh aws4-0    # First 4-GPU pod on node 4"
echo "  bash connect.sh aws4-1    # Second 4-GPU pod on node 4"
echo "  bash connect.sh aws5-0    # First 4-GPU pod on node 5"
echo "  bash connect.sh aws5-1    # Second 4-GPU pod on node 5"
echo ""
echo "📋 Pod Summary:"
echo "  aws0-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws1-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws2-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws3-0-8gpus: 8 GPUs (0,1,2,3,4,5,6,7)"
echo "  aws4-0-4gpus: 4 GPUs (0,1,2,3)"
echo "  aws4-1-4gpus: 4 GPUs (4,5,6,7)"
echo "  aws5-0-4gpus: 4 GPUs (0,1,2,3)"
echo "  aws5-1-4gpus: 4 GPUs (4,5,6,7)"
echo "  Total: 48 GPUs across 8 pods"

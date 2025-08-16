#!/bin/bash

# Launch script for GPU workstation pods
# Usage: bash launch.sh <node_idx> <ngpu>

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <node_idx> <ngpu>"
    echo "Example: $0 0 8    # Launch 8-GPU pod on node 0"
    echo "Example: $0 4 4    # Launch 4-GPU pod on node 4"
    exit 1
fi

NODE_IDX=$1
NGPU=$2

# Node mapping (0-7)
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

if [ $NODE_IDX -lt 0 ] || [ $NODE_IDX -gt 7 ]; then
    echo "Error: node_idx must be between 0 and 7"
    exit 1
fi

if [ $NGPU -ne 4 ] && [ $NGPU -ne 8 ]; then
    echo "Error: ngpu must be 4 or 8"
    exit 1
fi

NODE_NAME=${NODES[$NODE_IDX]}
echo "🚀 Launching $NGPU-GPU pod on node $NODE_IDX ($NODE_NAME)"

# Determine pod name based on node and GPU count
if [ $NGPU -eq 8 ]; then
    POD_NAME="aws${NODE_IDX}-0-8gpus"
    GPU_DEVICES="0,1,2,3,4,5,6,7"
else
    # For 4-GPU pods, we need to determine which 4 GPUs to use
    # This will be handled by the YAML template
    POD_NAME="aws${NODE_IDX}-0-4gpus"
    GPU_DEVICES="0,1,2,3"
fi

# Create pod YAML
cat > pod_yamls/${POD_NAME}.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  labels:
    app: gpu-workstation
    node-idx: "${NODE_IDX}"
    gpu-count: "${NGPU}"
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
        memory: "$([ $NGPU -eq 8 ] && echo "1000Gi" || echo "500Gi")"
        cpu: "$([ $NGPU -eq 8 ] && echo "90" || echo "45")"
        nvidia.com/gpu: "${NGPU}"
      limits:
        memory: "$([ $NGPU -eq 8 ] && echo "1Ti" || echo "500Gi")"
        cpu: "$([ $NGPU -eq 8 ] && echo "95" || echo "47")"
        nvidia.com/gpu: "${NGPU}"
    volumeMounts:
    - name: efs-storage
      mountPath: /home
    - name: dshm
      mountPath: /dev/shm
    env:
    - name: CUDA_VISIBLE_DEVICES
      value: "${GPU_DEVICES}"
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
echo "🔗 Connect to the pod:"
if [ $NGPU -eq 8 ]; then
    echo "  bash connect.sh aws${NODE_IDX}-0"
else
    echo "  bash connect.sh aws${NODE_IDX}-0"
fi
echo ""
echo "📊 Check GPU usage:"
echo "  bash check_usage.sh"

#!/bin/bash

# Launch script for GPU workstation pods
# Usage: bash launch.sh <pod_spec> <ngpu>
# Example: bash launch.sh 0-0 8
# Example: bash launch.sh 6-1 4

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <pod_spec> <ngpu>"
    echo "Example: $0 0-0 8    # Launch 8-GPU pod on node 0"
    echo "Example: $0 6-1 4    # Launch 4-GPU pod on node 6 (second pod)"
    exit 1
fi

POD_SPEC=$1
NGPU=$2

# Node mapping (0-7)
NODES=(
    "ip-172-31-129-163.us-west-2.compute.internal"
    "ip-172-31-130-216.us-west-2.compute.internal"
    "ip-172-31-131-175.us-west-2.compute.internal"
    "ip-172-31-136-213.us-west-2.compute.internal"
    "ip-172-31-144-249.us-west-2.compute.internal"
    "ip-172-31-150-2.us-west-2.compute.internal"
    "ip-172-31-159-22.us-west-2.compute.internal"
)

# Parse pod_spec
if [[ ! $POD_SPEC =~ ^([0-9]+)-([0-9]+)$ ]]; then
    echo "Error: Invalid pod_spec format. Expected <node_idx>-<pod_idx>"
    exit 1
fi

NODE_IDX=${BASH_REMATCH[1]}
POD_IDX=${BASH_REMATCH[2]}

if [ $NODE_IDX -lt 0 ] || [ $NODE_IDX -ge ${#NODES[@]} ]; then
    echo "Error: node_idx must be between 0 and $((${#NODES[@]} - 1))"
    exit 1
fi

# Validate NGPU and POD_IDX based on NODE_IDX
LAST_NODE_IDX=$((${#NODES[@]} - 1))
if [ $NODE_IDX -eq $LAST_NODE_IDX ]; then
    # Last node is a 4-GPU node
    if [ $NGPU -ne 4 ]; then
        echo "Error: Node $NODE_IDX only supports 4-GPU pods."
        exit 1
    fi
    if [ $POD_IDX -ne 0 ] && [ $POD_IDX -ne 1 ]; then
        echo "Error: For 4-GPU pods on node $NODE_IDX, pod_idx must be 0 or 1."
        exit 1
    fi
else
    # Other nodes are 8-GPU nodes
    if [ $NGPU -ne 8 ]; then
        echo "Error: Node $NODE_IDX only supports 8-GPU pods."
        exit 1
    fi
    if [ $POD_IDX -ne 0 ]; then
        echo "Error: For 8-GPU pods on node $NODE_IDX, pod_idx must be 0."
        exit 1
    fi
fi

NODE_NAME=${NODES[$NODE_IDX]}
echo "🚀 Launching $NGPU-GPU pod on node $NODE_IDX ($NODE_NAME)"

# Determine pod name and GPU devices
POD_NAME="pod${NODE_IDX}-${POD_IDX}"
if [ $NGPU -eq 8 ]; then
    GPU_DEVICES="0,1,2,3,4,5,6,7"
elif [ $NGPU -eq 4 ]; then
    if [ $POD_IDX -eq 0 ]; then
        GPU_DEVICES="0,1,2,3"
    elif [ $POD_IDX -eq 1 ]; then
        GPU_DEVICES="4,5,6,7"
    else
        echo "Error: Invalid pod_idx for 4-GPU pods. Must be 0 or 1."
        exit 1
    fi
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
      sizeLimit: 256Gi
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
echo "  bash connect.sh pod${NODE_IDX}-${POD_IDX}"
echo ""
echo "📊 Check GPU usage:"
echo "  bash check_usage.sh"

# GPU Workstation Deployment Plan

## 🎯 **Target Configuration: 6 Nodes, 8 Pods, 64 GPUs Total**

### **Node Mapping (0-7)**
```
Node 0: ip-172-31-129-163.us-west-2.compute.internal
Node 1: ip-172-31-130-216.us-west-2.compute.internal  
Node 2: ip-172-31-131-175.us-west-2.compute.internal
Node 3: ip-172-31-137-252.us-west-2.compute.internal
Node 4: ip-172-31-138-171.us-west-2.compute.internal
Node 5: ip-172-31-138-243.us-west-2.compute.internal
Node 6: ip-172-31-141-194.us-west-2.compute.internal
Node 7: ip-172-31-150-162.us-west-2.compute.internal
```

### **Deployment Plan (Nodes 0-5)**
```
Nodes 0-3: 8 GPUs each → 4 pods × 8 GPUs = 32 GPUs
Nodes 4-5: 8 GPUs each → 2 pods × 4 GPUs = 16 GPUs
Total: 48 GPUs from 6 nodes
```

### **Pod Naming Convention**
```
aws0-0-8gpus    # Node 0, 8 GPUs (0,1,2,3,4,5,6,7)
aws1-0-8gpus    # Node 1, 8 GPUs (0,1,2,3,4,5,6,7)
aws2-0-8gpus    # Node 2, 8 GPUs (0,1,2,3,4,5,6,7)
aws3-0-8gpus    # Node 3, 8 GPUs (0,1,2,3,4,5,6,7)
aws4-0-4gpus    # Node 4, 4 GPUs (0,1,2,3)
aws4-1-4gpus    # Node 4, 4 GPUs (4,5,6,7)
aws5-0-4gpus    # Node 5, 4 GPUs (0,1,2,3)
aws5-1-4gpus    # Node 5, 4 GPUs (4,5,6,7)
```

## 🚀 **Deployment Commands**

### **Phase 1: Deploy 8-GPU Pods (Nodes 0-3)**
```bash
bash launch.sh 0 8    # aws0-0-8gpus
bash launch.sh 1 8    # aws1-0-8gpus  
bash launch.sh 2 8    # aws2-0-8gpus
bash launch.sh 3 8    # aws3-0-8gpus
```

### **Phase 2: Deploy 4-GPU Pods (Nodes 4-5)**
```bash
bash launch.sh 4 4    # aws4-0-4gpus (GPUs 0,1,2,3)
bash launch.sh 4 4    # aws4-1-4gpus (GPUs 4,5,6,7)
bash launch.sh 5 4    # aws5-0-4gpus (GPUs 0,1,2,3)
bash launch.sh 5 4    # aws5-1-4gpus (GPUs 4,5,6,7)
```

**Note**: For nodes 4-5, you'll need to manually create the second 4-GPU pod since the launch script currently only creates one pod per node. You can either:
1. Modify the launch script to handle multiple pods per node
2. Manually create the second pod YAML files
3. Use a different deployment strategy

## 🔗 **Connection Commands**

### **Connect to 8-GPU Pods**
```bash
bash connect.sh aws0-0    # Connect to aws0-0-8gpus
bash connect.sh aws1-0    # Connect to aws1-0-8gpus
bash connect.sh aws2-0    # Connect to aws2-0-8gpus
bash connect.sh aws3-0    # Connect to aws3-0-8gpus
```

### **Connect to 4-GPU Pods**
```bash
bash connect.sh aws4-0    # Connect to aws4-0-4gpus (GPUs 0,1,2,3)
bash connect.sh aws4-1    # Connect to aws4-1-4gpus (GPUs 4,5,6,7)
bash connect.sh aws5-0    # Connect to aws5-0-4gpus (GPUs 0,1,2,3)
bash connect.sh aws5-1    # Connect to aws5-1-4gpus (GPUs 4,5,6,7)
```

## 📊 **Monitoring**

```bash
bash check_usage.sh    # Check GPU usage for all pods
```

## ⚠️ **Important Notes**

1. **Resource Limits**: Each pod requests 1000Gi memory and 90 CPU cores
2. **Node Selection**: Pods are pinned to specific nodes using nodeSelector
3. **Storage**: All pods mount FSx storage at `/home`
4. **Image**: Uses `hchen403/cuda128-miniconda:py312` with CUDA 12.8
5. **Shared Memory**: 64Gi shared memory for each pod

## 🔧 **Customization**

- **YAML Files**: Generated in `pod_yamls/` directory
- **Scripts**: All scripts are in the current directory
- **Node Mapping**: Update the NODES array in `launch.sh` if needed
- **Resource Limits**: Modify memory/CPU requests in the YAML template

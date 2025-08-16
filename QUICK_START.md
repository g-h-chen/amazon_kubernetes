# 🚀 Quick Start Guide

## **Deploy All Pods at Once**
```bash
bash deploy_all.sh    # Deploys all 8 pods across 6 nodes
```

## **Deploy Individual Pods**
```bash
# 8-GPU pods (nodes 0-3)
bash launch.sh 0 8    # aws0-0-8gpus
bash launch.sh 1 8    # aws1-0-8gpus
bash launch.sh 2 8    # aws2-0-8gpus
bash launch.sh 3 8    # aws3-0-8gpus

# 4-GPU pods (nodes 4-5)
bash launch.sh 4 4    # aws4-0-4gpus
bash launch.sh 5 4    # aws5-0-4gpus
```

## **Connect to Pods**
```bash
bash connect.sh aws0-0    # Connect to aws0-0-8gpus
bash connect.sh aws4-1    # Connect to aws4-1-4gpus
```

## **Monitor GPU Usage**
```bash
bash check_usage.sh    # Check all pods
```

## **Generated Files**
- **YAML files**: `pod_yamls/` directory
- **Scripts**: `launch.sh`, `connect.sh`, `check_usage.sh`, `deploy_all.sh`

## **Pod Configuration**
- **Image**: `hchen403/cuda128-miniconda:py312`
- **CUDA**: 12.8 with full toolkit
- **Storage**: FSx mounted at `/home`
- **Memory**: 1000Gi request, 1Ti limit
- **CPU**: 90 request, 95 limit
- **Shared Memory**: 64Gi per pod

## **Expected Result**
```
8 pods total:
- 4 pods × 8 GPUs = 32 GPUs (nodes 0-3)
- 4 pods × 4 GPUs = 16 GPUs (nodes 4-5)
Total: 48 GPUs across 6 nodes
```

# Interactive Kubernetes GPU Workstation Setup

This setup provides permanent interactive GPU pods that act like traditional compute nodes, making it easier for lab members to run training jobs without learning Kubernetes.

## Architecture Overview

- **8 Permanent Pods**: Distributed across 6 nodes with optimized GPU allocation
- **GPU Distribution**: 
  - **Nodes 0-3**: 8 GPUs each → 4 pods × 8 GPUs = 32 GPUs
  - **Nodes 4-5**: 8 GPUs each → 2 pods × 4 GPUs = 16 GPUs
  - **Total**: 48 GPUs across 8 pods
- **Persistent Storage**: 
  - `/home/efs/` - Your shared data and code (FSx storage)
  - `/home/conda_env/` - Conda environments (persisted to FSx)
- **Base Image**: CUDA 12.8 with Miniconda and Python 3.12





# User Workflow
## General idea
Now we have two sets of compute, one for debugging (aws7/8/9/10) and one for running long-time jobs (kubernetes pods). 
**They are completely separate in storage**.  

## Debug
Users should debug on aws7/8/9/10. These nodes can be connected via ssh and thus can be opened in vscode. Once finished debugging, you should move to kubernetes pods for training.



## Launch training

### First Time Setup (per user)
0. **Connect to aws-7/8/9/10**:

   Refer to [this](https://www.notion.so/250519-AWS-A100-1f815839118a80cca416ebccc23cbb7a) tutorial. Send request to visit.

1. **Connect to an available pod**:
   
   **Check the google sheet in the wechat group notice and fill your name!!!**
   ```bash
   # outside the pod
   cd /home/efs/kubernetes/amazon_kubernetes

   # For 8-GPU access
   bash connect.sh aws0-0    # or aws1-0, aws2-0, aws3-0
   
   # For 4-GPU access
   bash connect.sh aws4-0    # or aws4-1, aws5-0, aws5-1
   ```
   If you see:
   ```
   ubuntu@ip-172-31-6-254:/home/efs/kubernetes/amazon_kubernetes$ bash connect.sh aws4-0
   🔗 Connecting to 8-GPU pod: aws0-0-8gpus
   ✅ Pod aws0-0-8gpus is ready!
   💡 Tip: Use 'nvidia-smi' to check GPU status
   💡 Tip: Your conda env is in /home/efs/conda_envs/
   💡 Tip: Use 'conda activate <env_name>' to switch conda environments
   💡 Tip: Your data is in /home/efs/

   (base) root@aws4-0-4gpus:/home/efs# 
   ```
   it means you are in the one of the pods now!

2. **Create your conda environment**:

   **DO NOT use `conda create -n $envname`. Environments under `/opt/conda` will be deleted**.
   ```bash
   # Inside the pod
   $envname="user_envname" # e.g. hardy_llamafactory 
   conda create --prefix /home/efs/conda_envs/$envname python=3.12.0
   conda activate $envname
   # conda install pytorch torchvision torchaudio pytorch-cuda=12.8 -c pytorch -c nvidia
   # Install other packages as needed...
   ```
   **Your work persists**: conda environments, data, and code are all saved to FSx storage and can be accessed across pods!

3. **Launch training in tmux**:
   ```bash
   # Inside the pod
   myname=""
   tmux new -s $myname
   tmux a -t $myname -d
   # make your own dir
   mkdir -p /home/efs/$myname && cd /home/efs/$myname

   # clone code
   git clone xxx and cd xxx

   # download data
   bash download_data.sh # prepare by yourself
   # -> alternatively, you can copy files from aws to kubernetes pods:
   bash cp_to_pod.sh $local_file_or_dir $pod_file_or_dir # similar to cp -r $src $dst


   # launch training
   bash train.sh # your training script
   ```

4. **After training**: remove your name from google sheet so that others can use!
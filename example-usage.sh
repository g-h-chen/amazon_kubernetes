#!/bin/bash

# Example Usage Script for Interactive Workstation Pods
# This script demonstrates common workflows for lab members

echo "🚀 Interactive Workstation - Example Usage"
echo "=========================================="

show_help() {
    cat << EOF
Example Usage Script

Usage: $0 [COMMAND]

Commands:
    setup-env     Create a new conda environment with common ML packages
    check-gpu     Verify GPU access and CUDA installation
    example-job   Run a simple PyTorch training example
    tips          Show usage tips and best practices
    help          Show this help message

Examples:
    $0 setup-env           # Create a new environment called 'myproject'
    $0 check-gpu          # Test GPU functionality
    $0 example-job        # Run a simple training script
    $0 tips               # Get usage tips

Note: Run this script from inside a connected pod!
EOF
}

setup_environment() {
    local env_name="${1:-myproject}"
    
    echo "🔧 Setting up conda environment: $env_name"
    echo "=========================================="
    
    # Check if conda is available
    if ! command -v conda >/dev/null 2>&1; then
        echo "⚠️  Conda not found. Initializing..."
        if [ -f /home/conda_env/miniconda3/etc/profile.d/conda.sh ]; then
            source /home/conda_env/miniconda3/etc/profile.d/conda.sh
            export PATH="/home/conda_env/miniconda3/bin:$PATH"
        else
            echo "❌ Conda not installed. Please wait for pod initialization to complete."
            exit 1
        fi
    fi
    
    echo "Creating environment: $env_name"
    conda create -n "$env_name" python=3.10 -y
    
    echo "Activating environment..."
    source activate "$env_name"
    
    echo "Installing common ML packages..."
    conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia -y
    conda install numpy pandas matplotlib seaborn scikit-learn jupyter -y
    pip install transformers datasets accelerate wandb tensorboard
    
    echo "✅ Environment '$env_name' created successfully!"
    echo ""
    echo "To use this environment:"
    echo "  conda activate $env_name"
    echo ""
    echo "Installed packages:"
    conda list | grep -E "(torch|numpy|pandas|transformers)"
}

check_gpu() {
    echo "🎮 GPU Check"
    echo "============"
    
    echo "1. Checking nvidia-smi..."
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi
        echo "✅ nvidia-smi working"
    else
        echo "❌ nvidia-smi not found"
        return 1
    fi
    
    echo ""
    echo "2. Checking CUDA in Python..."
    python3 << 'EOF'
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"Number of GPUs: {torch.cuda.device_count()}")
    for i in range(torch.cuda.device_count()):
        print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
        print(f"  Memory: {torch.cuda.get_device_properties(i).total_memory / 1e9:.1f} GB")
else:
    print("❌ CUDA not available in PyTorch")
EOF
    
    echo ""
    echo "3. Simple GPU computation test..."
    python3 << 'EOF'
import torch
if torch.cuda.is_available():
    # Create tensors on GPU
    x = torch.randn(1000, 1000).cuda()
    y = torch.randn(1000, 1000).cuda()
    
    # Perform computation
    z = torch.mm(x, y)
    
    print(f"✅ GPU computation successful!")
    print(f"Result tensor shape: {z.shape}")
    print(f"Result device: {z.device}")
else:
    print("❌ Cannot test GPU computation - CUDA not available")
EOF
}

run_example_job() {
    echo "🤖 Example Training Job"
    echo "======================="
    
    # Create a simple training script
    cat > /tmp/simple_training.py << 'EOF'
import torch
import torch.nn as nn
import torch.optim as optim
import time

print("🔥 Simple PyTorch Training Example")
print("==================================")

# Check GPU
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using device: {device}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name()}")
    print(f"Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")

# Simple neural network
class SimpleNet(nn.Module):
    def __init__(self):
        super(SimpleNet, self).__init__()
        self.fc1 = nn.Linear(784, 128)
        self.fc2 = nn.Linear(128, 64)
        self.fc3 = nn.Linear(64, 10)
        self.relu = nn.ReLU()
        
    def forward(self, x):
        x = self.relu(self.fc1(x))
        x = self.relu(self.fc2(x))
        x = self.fc3(x)
        return x

# Create model and move to GPU
model = SimpleNet().to(device)
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

print(f"\nModel parameters: {sum(p.numel() for p in model.parameters()):,}")

# Generate random data (simulating MNIST)
batch_size = 64
num_batches = 100

print(f"\nStarting training...")
print(f"Batch size: {batch_size}")
print(f"Number of batches: {num_batches}")

start_time = time.time()

for batch_idx in range(num_batches):
    # Generate random data
    data = torch.randn(batch_size, 784).to(device)
    target = torch.randint(0, 10, (batch_size,)).to(device)
    
    # Forward pass
    optimizer.zero_grad()
    output = model(data)
    loss = criterion(output, target)
    
    # Backward pass
    loss.backward()
    optimizer.step()
    
    if batch_idx % 20 == 0:
        print(f"Batch {batch_idx:3d}/{num_batches} | Loss: {loss.item():.4f}")

end_time = time.time()
print(f"\n✅ Training completed!")
print(f"Total time: {end_time - start_time:.2f} seconds")
print(f"Average time per batch: {(end_time - start_time) / num_batches:.3f} seconds")

# Memory usage
if torch.cuda.is_available():
    print(f"GPU memory used: {torch.cuda.memory_allocated() / 1e9:.2f} GB")
    print(f"GPU memory cached: {torch.cuda.memory_reserved() / 1e9:.2f} GB")
EOF
    
    echo "Running example training script..."
    python3 /tmp/simple_training.py
    
    echo ""
    echo "✅ Example job completed!"
    echo "This demonstrates:"
    echo "  - GPU detection and usage"
    echo "  - Model creation and training"
    echo "  - Performance monitoring"
}

show_tips() {
    cat << 'EOF'
💡 Tips and Best Practices
==========================

🔧 Environment Management:
   - Create separate conda environments for different projects
   - Use descriptive names: conda create -n my-research-project
   - List environments: conda env list
   - Remove unused environments: conda env remove -n old-project

🎮 GPU Usage:
   - Check available GPUs: nvidia-smi
   - Monitor usage: watch -n 1 nvidia-smi
   - Test CUDA: python -c "import torch; print(torch.cuda.is_available())"
   - Clear GPU cache: torch.cuda.empty_cache()

📁 File Organization:
   - Store code in: /home/efs/your-project/
   - Store data in: /home/efs/datasets/
   - Conda envs in: /home/conda_env/ (automatic)
   - Use git for version control in /home/efs/

🏃 Long-Running Jobs:
   - Use screen/tmux for persistence: screen -S training
   - Detach with: Ctrl+A, D
   - Reattach with: screen -r training
   - List sessions: screen -ls

📊 Monitoring:
   - Check pod status: ../deploy.sh status
   - Monitor resources: ../monitor.sh usage
   - View GPU usage: ../monitor.sh gpus
   - Watch live: ../monitor.sh watch

🤝 Collaboration:
   - Check if pod is busy before starting big jobs
   - Use descriptive screen session names
   - Share conda environments: conda env export > environment.yml
   - Communicate long jobs with lab mates

⚡ Performance Tips:
   - Use appropriate batch sizes for your GPU memory
   - Monitor GPU utilization (should be >80% for training)
   - Use mixed precision training: torch.cuda.amp
   - Profile code: torch.profiler

🆘 Troubleshooting:
   - Pod not responding: kubectl describe pod <pod-name>
   - GPU not visible: check CUDA_VISIBLE_DEVICES
   - Out of memory: reduce batch size or model size
   - Conda issues: source /home/conda_env/miniconda3/etc/profile.d/conda.sh

📚 Useful Commands:
   - htop                    # CPU/Memory usage
   - nvidia-smi -l 1        # Live GPU monitoring  
   - du -sh /home/efs/*     # Check disk usage
   - conda info --envs      # List environments
   - pip list | grep torch  # Check PyTorch version
EOF
}

# Main script logic
case "${1:-help}" in
    setup-env)
        setup_environment "$2"
        ;;
    check-gpu)
        check_gpu
        ;;
    example-job)
        run_example_job
        ;;
    tips)
        show_tips
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac


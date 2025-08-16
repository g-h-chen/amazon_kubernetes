#!/bin/bash

# Script to copy files from local directory to a pod directory
# Usage: bash cp_to_pod.sh <local_dir> <pod_dir>
# Example: bash cp_to_pod.sh /home/efs/hardychen/workspaces /home/efs/hardychen/workspaces

set -e  # Exit on any error

# Check arguments
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "📋 Usage: bash cp_to_pod.sh <local_path> <pod_path>"
    echo ""
    echo "📁 Arguments:"
    echo "  local_path - Local file or directory to copy from"
    echo "  pod_path   - Destination path in the pod"
    echo ""
    echo "💡 Examples:"
    echo "  # Copy a directory"
    echo "  bash cp_to_pod.sh /home/efs/hardychen/workspaces /home/efs/hardychen/workspaces"
    echo "  bash cp_to_pod.sh ./my_project /home/efs/my_project"
    echo ""
    echo "  # Copy a file"
    echo "  bash cp_to_pod.sh ./train.py /home/efs/train.py"
    echo "  bash cp_to_pod.sh /home/efs/data/model.pt /home/efs/models/model.pt"
    echo ""
    echo "🔍 The script will automatically find an available pod to copy to."
    echo "🔍 Supports both files and directories automatically."
    exit 0
fi

if [ $# -ne 2 ]; then
    echo "❌ Error: Expected 2 arguments, got $#"
    echo "Use 'bash cp_to_pod.sh --help' for usage information"
    exit 1
fi

LOCAL_PATH="$1"
POD_PATH="$2"

# Validate local path (can be file or directory)
if [ ! -e "$LOCAL_PATH" ]; then
    echo "❌ Error: Local path '$LOCAL_PATH' does not exist"
    exit 1
fi

# Determine if it's a file or directory
if [ -d "$LOCAL_PATH" ]; then
    IS_DIRECTORY=true
    echo "📁 Source is a directory"
elif [ -f "$LOCAL_PATH" ]; then
    IS_DIRECTORY=false
    echo "📄 Source is a file"
else
    echo "❌ Error: '$LOCAL_PATH' is neither a file nor a directory"
    exit 1
fi

echo "📁 Copying from: $LOCAL_PATH"
if [ "$IS_DIRECTORY" = true ]; then
    echo "📁 Copying to pod directory: $POD_PATH"
else
    echo "📄 Copying to pod file: $POD_PATH"
fi
echo ""

# Define all available pods
PODS=(
    "aws0-0"  # 8-GPU pod
    "aws1-0"  # 8-GPU pod
    "aws2-0"  # 8-GPU pod
    "aws3-0"  # 8-GPU pod
    "aws4-0"  # 4-GPU pod
    "aws4-1"  # 4-GPU pod
    "aws5-0"  # 4-GPU pod
    "aws5-1"  # 4-GPU pod
)

# Find an available pod
AVAILABLE_POD=""
for pod in "${PODS[@]}"; do
    # echo "🔍 Checking pod: $pod"
    
    # Check if pod exists and is running
    if kubectl get pods | grep -q "$pod.*Running"; then
        # echo "✅ Pod $pod is available and running"
        AVAILABLE_POD="$pod"
        break
    else
        echo ""
        # echo "❌ Pod $pod is not available or not running"
    fi
done

if [ -z "$AVAILABLE_POD" ]; then
    echo "❌ Error: No available pods found. Please check pod status with:"
    echo "   bash check_usage.sh"
    exit 1
fi

echo ""
echo "🚀 Using pod: $AVAILABLE_POD"
echo ""

# Get the full pod name
if [[ "$AVAILABLE_POD" == "aws"[0-3]"-0" ]]; then
    FULL_POD_NAME="${AVAILABLE_POD}-8gpus"
elif [[ "$AVAILABLE_POD" == "aws"[4-5]"-"[0-1] ]]; then
    FULL_POD_NAME="${AVAILABLE_POD}-4gpus"
else
    echo "❌ Error: Invalid pod format: $AVAILABLE_POD"
    exit 1
fi

# echo "📋 Full pod name: $FULL_POD_NAME"
echo ""

# Handle destination directory creation
if [ "$IS_DIRECTORY" = true ]; then
    # For directories, create the destination directory
    echo "📁 Creating destination directory in pod..."
    kubectl exec "$FULL_POD_NAME" -- mkdir -p "$POD_PATH"
else
    # For files, create the parent directory
    echo "📁 Creating parent directory in pod..."
    kubectl exec "$FULL_POD_NAME" -- mkdir -p "$(dirname "$POD_PATH")"
fi

# Copy files using kubectl cp
if [ "$IS_DIRECTORY" = true ]; then
    echo "📤 Copying directory to pod..."
    echo "⏳ This may take a while depending on directory size..."
    
    # Use kubectl cp to copy the directory
    kubectl cp "$LOCAL_PATH" "$FULL_POD_NAME:$POD_PATH"
else
    echo "📤 Copying file to pod..."
    echo "⏳ This may take a while depending on file size..."
    
    # Use kubectl cp to copy the file
    kubectl cp "$LOCAL_PATH" "$FULL_POD_NAME:$POD_PATH"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Copy completed successfully!"
    if [ "$IS_DIRECTORY" = true ]; then
        echo "📁 Source directory: $LOCAL_PATH"
        # echo "📁 Destination directory: $FULL_POD_NAME:$POD_PATH"
        echo "📁 Destination directory: Pod:$POD_PATH"
        echo ""
        # echo "💡 You can now connect to the pod with:"
        # echo "   bash connect.sh $AVAILABLE_POD"
        # echo ""
        # echo "💡 And verify the files are there with:"
        # echo "   ls -la $POD_PATH"
    else
        echo "📄 Local path: $LOCAL_PATH"
        # echo "📄 Destination file: $FULL_POD_NAME:$POD_PATH"
        echo "📄 Destination file: Pod:$POD_PATH"
        # echo ""
        # echo "💡 You can now connect to the pod with:"
        # echo "   bash connect.sh $AVAILABLE_POD"
        # echo ""
        # echo "💡 And verify the file is there with:"
        # echo "   ls -la $(dirname "$POD_PATH")"
    fi
else
    echo ""
    echo "❌ Error: Failed to copy"
    exit 1
fi

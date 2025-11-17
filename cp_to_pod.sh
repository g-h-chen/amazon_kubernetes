#!/bin/bash

# Script to copy files from local directory to a pod directory
# Usage: bash cp_to_pod.sh <pod_spec> <local_path> <pod_path>
# Example: bash cp_to_pod.sh aws0-0 ./my_data /home/efs/data

set -e  # Exit on any error

# Check arguments
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "📋 Usage: bash cp_to_pod.sh <pod_spec> <local_path> <pod_path>"
    echo ""
    echo "📁 Arguments:"
    echo "  pod_spec   - Identifier for the target pod (e.g., aws0-0, aws6-1)"
    echo "  local_path - Local file or directory to copy from"
    echo "  pod_path   - Destination path in the pod"
    echo ""
    echo "💡 Examples:"
    echo "  # Copy a directory to pod aws0-0"
    echo "  bash cp_to_pod.sh aws0-0 ./my_project /home/efs/my_project"
    echo ""
    echo "  # Copy a file to pod aws6-1"
    echo "  bash cp_to_pod.sh aws6-1 ./train.py /home/efs/train.py"
    echo ""
    echo "  # Copy to a reserved node"
    echo "  bash cp_to_pod.sh aws8-0 ./model.pth /home/efs/models/"
    exit 0
fi

if [ $# -ne 3 ]; then
    echo "❌ Error: Expected 3 arguments, got $#"
    echo "Use 'bash cp_to_pod.sh --help' for usage information"
    exit 1
fi

POD_SPEC="$1"
LOCAL_PATH="$2"
POD_PATH="$3"

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

# Parse the pod identifier to get the full pod name
if [[ $POD_SPEC =~ ^aws([0-9]+)-([0-9]+)$ ]]; then
    NODE_IDX=${BASH_REMATCH[1]}
    POD_NUM=${BASH_REMATCH[2]}
else
    echo "Error: Invalid pod_spec format. Use 'aws<node>-<pod_num>'"
    echo "Example: aws0-0, aws6-1"
    exit 1
fi

# Determine full pod name based on the deployment logic
if [ $NODE_IDX -le 5 ]; then
    # Nodes 0-5 have 8-GPU pods
    if [ $POD_NUM -eq 0 ]; then
        FULL_POD_NAME="aws${NODE_IDX}-0-8gpus"
    else
        echo "Error: Node ${NODE_IDX} only has one pod (use aws${NODE_IDX}-0)"
        exit 1
    fi
elif [ $NODE_IDX -le 7 ]; then
    # Nodes 6-7 have 4-GPU pods
    if [ $POD_NUM -eq 0 ]; then
        FULL_POD_NAME="aws${NODE_IDX}-0-4gpus"
    elif [ $POD_NUM -eq 1 ]; then
        FULL_POD_NAME="aws${NODE_IDX}-1-4gpus"
    else
        echo "Error: Invalid pod number for node ${NODE_IDX}. Use 0 or 1."
        exit 1
    fi
elif [ $NODE_IDX -le 9 ]; then
    # Nodes 8-9 are reserved 8-GPU pods
    if [ $POD_NUM -eq 0 ]; then
        FULL_POD_NAME="aws${NODE_IDX}-0-8gpus"
    else
        echo "Error: Node ${NODE_IDX} only has one pod (use aws${NODE_IDX}-0)"
        exit 1
    fi
else
    echo "Error: Node ${NODE_IDX} is not configured for GPU pods (valid nodes are 0-9)"
    exit 1
fi

echo "🚀 Targeting pod: $FULL_POD_NAME"
echo ""

# Check if pod exists and is running
if ! kubectl get pod "$FULL_POD_NAME" >/dev/null 2>&1; then
    echo "❌ Error: Pod $FULL_POD_NAME not found"
    echo "Available pods:"
    kubectl get pods -l app=gpu-workstation
    exit 1
fi

POD_STATUS=$(kubectl get pod "$FULL_POD_NAME" -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo "❌ Error: Pod $FULL_POD_NAME is not running (status: $POD_STATUS)"
    exit 1
fi

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

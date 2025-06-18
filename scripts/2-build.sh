#!/bin/bash
set -e

# Script to build the BitNet Lambda Docker image

echo "Building BitNet Lambda Docker image..."

# Check if temp/BitNet exists
if [ ! -d "temp/BitNet" ]; then
    echo "Error: BitNet code not found in temp/BitNet"
    echo "Please run initialize.sh first"
    exit 1
fi

# Check if model exists and warn if not
if [ ! -f "temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf" ]; then
    echo "Warning: BitNet model not found in temp/models/BitNet-b1.58-2B-4T/"
    echo "The Docker image will be built, but you'll need to mount the model at runtime"
    echo "To download the model, run initialize.sh"
    echo ""
    echo "Proceeding with build anyway..."
fi

# Build Docker image
echo "Building Docker image (this may take some time)..."
docker build --no-cache -t bitnet-lambda -f App/Dockerfile .

echo "Build complete!"
echo "Docker image 'bitnet-lambda' is now available"
echo "You can now run deploy.sh to start the container locally"

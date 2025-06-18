#!/bin/bash
set -e

# Script to initialize the BitNet project
# Downloads BitNet code and model

echo "Initializing BitNet Lambda project..."

# Create temp directory if it doesn't exist
mkdir -p temp/models/BitNet-b1.58-2B-4T

# Remove existing BitNet directory if it exists
if [ -d "temp/BitNet" ]; then
    echo "Removing existing BitNet directory..."
    rm -rf temp/BitNet
fi

# Clone BitNet repository with submodules
echo "Cloning BitNet repository with submodules..."
git clone --recurse-submodules https://github.com/microsoft/BitNet.git temp/BitNet

echo "BitNet code is now available in temp directory"

# Download model using curl for better compatibility
echo "Downloading BitNet model..."
echo "This may take some time as the model is several gigabytes in size."
curl -L https://huggingface.co/microsoft/BitNet-b1.58-2B-4T-gguf/resolve/main/ggml-model-i2_s.gguf \
    --output temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf \
    --progress-bar

echo "Model download complete!"
echo "The model is now available at temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf"

echo "Initialization complete!"
echo "You can now run build.sh to create the Docker image"

#!/bin/bash

# BitNet Lambda Initialization Script
# This script downloads BitNet source code and the model file

set -e

echo "🚀 Initializing BitNet Lambda project..."

# Create temp directory
mkdir -p temp
cd temp

# Clone BitNet repository
if [ ! -d "BitNet" ]; then
    echo "📦 Cloning BitNet repository..."
    git clone https://github.com/microsoft/BitNet.git
    echo "📦 Initializing git submodules..."
    cd BitNet
    git submodule update --init --recursive
    cd ..
    echo "✅ BitNet repository cloned"
else
    echo "✅ BitNet repository already exists"
fi

# Create models directory
mkdir -p models/BitNet-b1.58-2B-4T

# Download model file if it doesn't exist
MODEL_FILE="models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf"
if [ ! -f "$MODEL_FILE" ]; then
    echo "📥 Downloading BitNet 1.58B model (this may take a while)..."
    
    # Try to download from Hugging Face
    if command -v wget >/dev/null 2>&1; then
        wget -O "$MODEL_FILE" "https://huggingface.co/1bitLLM/bitnet_b1_58-2B-4T/resolve/main/ggml-model-i2_s.gguf"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$MODEL_FILE" "https://huggingface.co/1bitLLM/bitnet_b1_58-2B-4T/resolve/main/ggml-model-i2_s.gguf"
    else
        echo "❌ Error: Neither wget nor curl found."
        echo "   Please manually download from:"
        echo "   https://huggingface.co/1bitLLM/bitnet_b1_58-2B-4T/resolve/main/ggml-model-i2_s.gguf"
        exit 1
    fi
    
    echo "✅ Model downloaded successfully"
else
    echo "✅ Model file already exists"
fi

# Verify files exist
cd ..
if [ -d "temp/BitNet" ] && [ -f "temp/$MODEL_FILE" ]; then
    echo ""
    echo "🎉 Initialization complete!"
    echo "   - BitNet source: temp/BitNet/"
    echo "   - Model file: temp/$MODEL_FILE"
    echo ""
    echo "🚀 You can now run: ./scripts/2-deploy-lambda.sh"
else
    echo "❌ Initialization failed. Please check the error messages above."
    exit 1
fi

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

# Download BitNet model using Python script
echo "📥 Downloading BitNet 1.58B model (this may take a while)..."
cd ../cdk
if [ ! -d ".venv" ]; then
    python -m venv .venv
fi
source .venv/bin/activate
pip install -r requirements.txt > /dev/null 2>&1
python download_model.py
cd ../temp
cd ..

# Verify model download
if [ -f "temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf" ]; then
    MODEL_SIZE=$(stat -f%z "temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf" 2>/dev/null || stat -c%s "temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf" 2>/dev/null || echo "0")
    if [ "$MODEL_SIZE" -gt 1000000 ]; then
        echo "✅ Model downloaded successfully"
    else
        echo "❌ Model download failed or file is too small"
        exit 1
    fi
else
    echo "❌ Model file not found"
    exit 1
fi

# Verify files exist
if [ -d "temp/BitNet" ] && [ -f "temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf" ]; then
    echo ""
    echo "🎉 Initialization complete!"
    echo "   - BitNet source: temp/BitNet/"
    echo "   - Model file: temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf"
    echo ""
    echo "🚀 You can now run: ./scripts/2-deploy-lambda.sh"
else
    echo "❌ Initialization failed. Please check the error messages above."
    exit 1
fi

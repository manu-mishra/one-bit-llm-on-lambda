#!/bin/bash
set -e

# Script to deploy the BitNet Lambda Docker container locally

echo "Deploying BitNet Lambda container locally..."

# Check if Docker image exists
if ! docker image inspect bitnet-lambda &> /dev/null; then
    echo "Error: Docker image 'bitnet-lambda' not found"
    echo "Please run build.sh first"
    exit 1
fi

# Check if model exists and warn if not
if [ ! -f "temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf" ]; then
    echo "Error: BitNet model not found in temp/models/BitNet-b1.58-2B-4T/"
    echo "The container will not work without the model"
    echo "Please run initialize.sh to download the model"
    exit 1
fi

# Stop any existing container
echo "Stopping any existing bitnet-lambda container..."
docker stop bitnet-lambda-container 2>/dev/null || true
docker rm bitnet-lambda-container 2>/dev/null || true

# Run the container with model volume mount
echo "Starting BitNet Lambda container..."
docker run -d \
    --name bitnet-lambda-container \
    -p 8080:8080 \
    -v "$(pwd)/temp/models/BitNet-b1.58-2B-4T:/app/models/BitNet-b1.58-2B-4T" \
    bitnet-lambda

echo "Deployment complete!"
echo "BitNet server is now running at http://localhost:8080"
echo "You can test the API with:"
echo "  curl -X POST http://localhost:8080/completion -H 'Content-Type: application/json' -d '{\"prompt\": \"Hello, world\", \"n_predict\": 50}'"
echo "To view server logs:"
echo "  docker logs bitnet-lambda-container"
echo "To stop the container:"
echo "  docker stop bitnet-lambda-container"

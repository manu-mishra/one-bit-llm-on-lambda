# Multi-stage build for BitNet Lambda inference

# Build stage - using a more complete base image with build tools
FROM python:3.9-bullseye AS builder

# Install system dependencies
RUN apt-get update && \
    apt-get install -y cmake build-essential git clang

# Set up working directory
WORKDIR /app

# Copy BitNet repository from local temp directory
COPY temp/BitNet /app/BitNet

# Create models directory
RUN mkdir -p /app/BitNet/models/BitNet-b1.58-2B-4T

# Copy pre-downloaded model
COPY temp/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf /app/BitNet/models/BitNet-b1.58-2B-4T/

# Install Python dependencies
WORKDIR /app/BitNet
RUN pip install --no-cache-dir -r requirements.txt

# Install gguf
RUN pip install 3rdparty/llama.cpp/gguf-py

# Generate the kernel files
RUN python utils/codegen_tl1.py --model bitnet_b1_58-3B --BM 160,320,320 --BK 64,128,64 --bm 32,64,32

# Build the project using BitNet's build process with static linking
RUN cmake -B build -DBITNET_ARM_TL1=ON -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DBUILD_SHARED_LIBS=OFF
RUN cmake --build build --config Release

# Runtime stage - using a smaller base image
FROM python:3.9-slim

# Install required runtime dependencies
RUN apt-get update && \
    apt-get install -y libomp5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy only necessary files from builder
COPY --from=builder /app/BitNet/build/bin/llama-server /app/bin/
COPY --from=builder /app/BitNet/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf /app/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf
COPY --from=builder /app/BitNet/run_inference_server.py /app/

# Install minimal runtime dependencies
RUN pip install --no-cache-dir requests

# Create a simple server script for testing
RUN echo '#!/usr/bin/env python3\n\
import os\n\
import subprocess\n\
import time\n\
import signal\n\
\n\
def signal_handler(sig, frame):\n\
    print("Shutting down server...")\n\
    if server_process:\n\
        server_process.terminate()\n\
    exit(0)\n\
\n\
signal.signal(signal.SIGTERM, signal_handler)\n\
signal.signal(signal.SIGINT, signal_handler)\n\
\n\
print("Starting BitNet server...")\n\
\n\
# Start the server\n\
server_process = subprocess.Popen([\n\
    "/app/bin/llama-server",\n\
    "-m", "/app/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf",\n\
    "-c", "2048",\n\
    "-t", "2",\n\
    "--host", "0.0.0.0",\n\
    "--port", "8080",\n\
    "-ngl", "0"\n\
], stdout=subprocess.PIPE, stderr=subprocess.PIPE)\n\
\n\
print("BitNet server started")\n\
\n\
# Keep the container running\n\
try:\n\
    while True:\n\
        time.sleep(1)\n\
except KeyboardInterrupt:\n\
    print("Shutting down server...")\n\
    server_process.terminate()\n\
' > /app/server.py

# Make the server script executable
RUN chmod +x /app/server.py

# Set working directory
WORKDIR /app

# Expose the server port
EXPOSE 8080

# Set the CMD to run the server
CMD ["python3", "/app/server.py"]

# Install minimal runtime dependencies
RUN pip install --no-cache-dir requests

# Create a simple server script for testing
RUN echo '#!/usr/bin/env python3\n\
import os\n\
import subprocess\n\
import time\n\
import signal\n\
\n\
def signal_handler(sig, frame):\n\
    print("Shutting down server...")\n\
    if server_process:\n\
        server_process.terminate()\n\
    exit(0)\n\
\n\
signal.signal(signal.SIGTERM, signal_handler)\n\
signal.signal(signal.SIGINT, signal_handler)\n\
\n\
print("Starting BitNet server...")\n\
\n\
# Start the server\n\
server_process = subprocess.Popen([\n\
    "/app/bin/llama-server",\n\
    "-m", "/app/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf",\n\
    "-c", "2048",\n\
    "-t", "2",\n\
    "--host", "0.0.0.0",\n\
    "--port", "8080",\n\
    "-ngl", "0"\n\
], stdout=subprocess.PIPE, stderr=subprocess.PIPE)\n\
\n\
print("BitNet server started")\n\
\n\
# Keep the container running\n\
try:\n\
    while True:\n\
        time.sleep(1)\n\
except KeyboardInterrupt:\n\
    print("Shutting down server...")\n\
    server_process.terminate()\n\
' > /app/server.py

# Make the server script executable
RUN chmod +x /app/server.py

# Set working directory
WORKDIR /app

# Expose the server port
EXPOSE 8080

# Set the CMD to run the server
CMD ["python3", "/app/server.py"]

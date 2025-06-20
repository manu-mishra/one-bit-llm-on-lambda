# BitNet Lambda: Deploying a 1.58-bit Large Language Model on AWS Lambda

This project demonstrates how to deploy [Microsoft's BitNet](https://github.com/microsoft/BitNet) b1.58 2B4T model—a 1.58-bit quantized large language model (LLM)—on Amazon Web Services (AWS) Lambda. It enables serverless inference using CPU-only environments.

---

## Architecture Overview

![BitNet Lambda Architecture](docs/infra.svg)

The deployment architecture uses serverless execution:
- [AWS Lambda](https://aws.amazon.com/lambda/) serves as the compute engine for model inference. It runs a container with the quantized BitNet model.
- [Amazon Elastic Container Registry (Amazon ECR)](https://aws.amazon.com/ecr/) hosts the container image built with `bitnet.cpp` and the BitNet model weights.
- [Amazon CloudWatch Logs](https://aws.amazon.com/cloudwatch/) captures AWS Lambda execution logs for debugging and monitoring.
- [AWS Identity and Access Management (IAM)](https://aws.amazon.com/iam/) roles provide permissions for AWS Lambda execution, logging, and image access from Amazon ECR.

---

## Why Deploy Microsoft BitNet on AWS Lambda?

Microsoft's BitNet b1.58 is a large language model trained using 1.58-bit quantization, utilizing ternary values {-1, 0, +1}. Compared to full-precision models:
- It reduces model size and memory requirements.
- It improves CPU inference efficiency and requires no GPUs.
- It consumes less memory and power, suitable for edge and serverless deployments.

These characteristics make Microsoft BitNet suitable for environments such as AWS Lambda, where GPU access is not available and compute is billed per millisecond.

---

## Getting Started

### Prerequisites
- AWS CLI configured with appropriate permissions
- Python 3.9+ installed
- Hugging Face account and access token

### 1. Clone and Initialize
```bash
git clone https://github.com/your-username/one-bit-llm-on-lambda.git
cd one-bit-llm-on-lambda
./scripts/1-initialize.sh
```

**Important:** The initialization script will prompt you for a Hugging Face token to download the BitNet model. 
- Get your token from: https://huggingface.co/settings/tokens
- Create a token with "Read" permissions
- The script includes retry logic if authentication fails

This step downloads the Microsoft BitNet source and model (about 1.1 GB) and prepares the local environment.

### 2. Deploy the Inference Stack
```bash
cd cdk && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && cd ..
./scripts/2-deploy-lambda.sh
```

This uses the AWS Cloud Development Kit (AWS CDK) to provision AWS Lambda, Amazon ECR, IAM roles, and other supporting infrastructure.

### 3. Run a Test Inference
```bash
echo '{"prompt":"User: What'\''s the difference between 1-bit and 8-bit quantization?\n\nAssistant:","n_predict":10}' | base64 | aws lambda invoke --function-name bitnet-lambda-dev-function --region us-east-1 --payload file:///dev/stdin response.json && cat response.json
```

You can also use the AWS Command Line Interface (AWS CLI) directly to invoke the AWS Lambda function and generate responses from the model.

---

## Configuration

### AWS Lambda Memory
Memory allocation can be adjusted in `cdk/env_config.py`:
```python
LAMBDA_MEMORY_SIZE = 2048  # Memory size in MB
```

## Model Hosting in Lambda

### Container-Based Deployment
This project uses a container image approach to deploy the BitNet model directly within the Lambda function. This design choice has several implications:

#### Why Container Images?
- Model Size: The BitNet 1.58B model (~1.1GB) plus dependencies exceed Lambda's 250MB ZIP limit
- Native Dependencies: BitNet requires compiled C++ libraries (llama.cpp) that are easier to manage in containers
- Reproducible Builds: Docker ensures consistent environments across development and production

#### Build Cycle Changes
The deployment process includes several key steps to accommodate the embedded model:

1. Model Download: The initialization script downloads the BitNet model from Hugging Face to `temp/models/`
2. Multi-Stage Build: The Dockerfile uses a builder stage to compile BitNet and a runtime stage for the final image
3. Lambda-Specific Optimizations: 
   - OpenMP Disabled: Built with `-DGGML_OPENMP=OFF` to avoid shared memory issues in Lambda
   - Single-Threaded Mode: Environment variables force single-threaded execution
   - ARM Optimization: Uses `BITNET_ARM_TL1=ON` for ARM64 Lambda runtime
4. Model Embedding: The model file is copied directly into the container image during build
5. ECR Push: The complete container (with model) is pushed to Amazon ECR
6. Lambda Deployment: Lambda pulls the container image containing both code and model

#### Lambda Runtime Optimizations
The Lambda handler includes specific environment variable overrides to ensure proper model warm-up:

```python
# OpenMP configuration for Lambda single-threaded environment
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['OMP_THREAD_LIMIT'] = '1'
os.environ['GGML_OPENMP'] = 'OFF'
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['OPENBLAS_NUM_THREADS'] = '1'
```

These settings prevent threading conflicts and shared memory issues that can cause model initialization failures in Lambda's sandboxed environment.

---

## Performance Analysis

### Comprehensive Benchmark Results

I conducted extensive performance testing across different memory configurations with varying token generation requirements. Each configuration was tested with:
- 1 Cold Start (n_predict=10)
- 3 Warm Starts (n_predict=10, 50, 100)

#### Performance Results Table

| Memory (MB) | Test Type | N_Predict | Response Time (s) |
|-------------|-----------|-----------|-------------------|
| 2048 (2GB) | COLD_START | 10 | 12 |
| 2048 (2GB) | WARM_1 | 10 | 7 |
| 2048 (2GB) | WARM_2 | 50 | 18 |
| 2048 (2GB) | WARM_3 | 100 | 32 |
| 4096 (4GB) | COLD_START | 10 | 78 |
| 4096 (4GB) | WARM_1 | 10 | 7 |
| 4096 (4GB) | WARM_2 | 50 | 17 |
| 4096 (4GB) | WARM_3 | 100 | 32 |
| 6144 (6GB) | COLD_START | 10 | 13 |
| 6144 (6GB) | WARM_1 | 10 | 6 |
| 6144 (6GB) | WARM_2 | 50 | 18 |
| 6144 (6GB) | WARM_3 | 100 | 32 |
| 8192 (8GB) | COLD_START | 10 | 12 |
| 8192 (8GB) | WARM_1 | 10 | 7 |
| 8192 (8GB) | WARM_2 | 50 | 18 |
| 8192 (8GB) | WARM_3 | 100 | 32 |
| 10240 (10GB) | COLD_START | 10 | 12 |
| 10240 (10GB) | WARM_1 | 10 | 7 |
| 10240 (10GB) | WARM_2 | 50 | 18 |
| 10240 (10GB) | WARM_3 | 100 | 32 |

### Inference Parameters
The following JSON structure is passed to the AWS Lambda function for custom inference:
```json
{
  "prompt": "User: What's the difference between 1-bit and 8-bit quantization?\n\nAssistant:",
  "n_predict": 32,
  "temperature": 0.7,
  "top_p": 0.9,
  "top_k": 40,
  "repeat_penalty": 1.1
}
```

## Testing and Monitoring

### Performance Testing
```bash
# Quick functionality test
./scripts/3-test-lambda.sh

# Comprehensive memory benchmark
./scripts/5-benchmark.sh
```

The benchmark script runs comprehensive tests across all memory configurations with cold start detection and varying token generation requirements.

### Monitoring and Debugging
- Amazon CloudWatch Logs displays all logs emitted during AWS Lambda function execution
- AWS Management Console shows metrics like invocation count, duration, errors, and concurrency
- Performance Patterns: Response time scales with token count (n_predict parameter)

---

## Project Layout
```
one-bit-llm-on-lambda/
├── app/
│   ├── lambda_handler.py
│   └── Dockerfile.lambda
├── cdk/
│   ├── download_model.py      # Hugging Face model downloader
│   └── requirements.txt       # Includes huggingface_hub
├── docs/
├── scripts/
│   ├── 1-initialize.sh        # Downloads BitNet + model with HF auth
│   ├── 2-deploy-lambda.sh     # Deploys infrastructure
│   ├── 3-test-lambda.sh       # Tests deployment
│   └── 5-benchmark.sh         # Comprehensive memory benchmarks
└── temp/ (git ignored files)
```

Each shell script is modular and isolated:
- `1-initialize.sh`: Downloads Microsoft BitNet source and model with Hugging Face authentication
- `2-deploy-lambda.sh`: Deploys all AWS infrastructure using AWS CDK
- `3-test-lambda.sh`: Sends a sample prompt to the AWS Lambda endpoint for testing
- `5-benchmark.sh`: Runs comprehensive performance benchmarks across memory configurations

---

## Cost Optimization

Lambda pricing is based on memory allocation and execution time. Users can evaluate the performance data above to determine the optimal memory configuration for their specific use case and cost requirements.

Cold Start Mitigation Options:
- Provisioned Concurrency: Eliminates cold starts but increases base cost
- Keep-Warm Strategy: Periodic invocations to maintain warm instances
- Right-Sizing: Choose memory based on performance requirements and budget

---

## License & Credits
- MIT License (see `LICENSE` file)
- Based on [Microsoft BitNet](https://github.com/microsoft/BitNet) research for 1-bit LLMs
- Uses [llama.cpp](https://github.com/ggerganov/llama.cpp) as the runtime for model inference
- Model downloaded from [Microsoft's official Hugging Face repository](https://huggingface.co/microsoft/bitnet-b1.58-2B-4T-gguf)

---

This project demonstrates the feasibility of running modern, low-bit large language models in fully serverless environments using CPU-only infrastructure. The performance analysis provides comprehensive data to help users choose appropriate memory configurations based on their specific requirements and cost constraints.

# BitNet Lambda: Serverless 1-bit LLM on AWS Lambda

Deploy Microsoft's BitNet 1.58-bit quantized language model on AWS Lambda for cost-effective, serverless AI inference.

## 🏗️ Architecture

![BitNet Lambda Architecture](docs/infra.svg)

The architecture consists of:
- **AWS Lambda Function**: Serverless compute running BitNet inference in a container
- **ECR Repository**: Stores the Docker container image with BitNet and the model
- **CloudWatch Logs**: Captures function execution logs for monitoring and debugging
- **IAM Role**: Provides necessary permissions for Lambda execution and logging
- **BitNet Model**: 1.58-bit quantized model embedded within the container image

## 🚀 Quick Start

### 1. Initialize Project
```bash
git clone https://github.com/your-username/one-bit-llm-on-lambda.git
cd one-bit-llm-on-lambda

# Download BitNet source code and model (~1.3GB)
./scripts/1-initialize.sh
```

### 2. Deploy to AWS Lambda

```bash
# Setup CDK environment
cd cdk && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && cd ..

# Deploy to AWS Lambda
./scripts/2-deploy-lambda.sh

# Test AWS deployment
./scripts/3-test-lambda.sh
```

## 📁 Project Structure

```
one-bit-llm-on-lambda/
├── app/
│   ├── lambda_handler.py      # Lambda function handler
│   └── Dockerfile.lambda      # Lambda container configuration
├── cdk/                       # AWS CDK infrastructure code
├── docs/
│   ├── infra.dot              # Architecture diagram source
│   └── infra.svg              # Architecture diagram
├── scripts/
│   ├── 1-initialize.sh        # Downloads BitNet source and model
│   ├── 2-deploy-lambda.sh     # AWS deployment script
│   └── 3-test-lambda.sh       # AWS testing script
└── temp/                      # BitNet source & model (gitignored)
```

## 🛠️ Prerequisites

### For AWS Deployment
- AWS CLI configured with appropriate permissions
- AWS CDK installed (`npm install -g aws-cdk`)
- Python 3.9+ for CDK
- Docker for building containers
- 10GB+ free disk space
- Sufficient AWS permissions for Lambda, ECR, CloudWatch, and IAM

### System Requirements
- macOS, Linux, or Windows with WSL2
- 8GB+ RAM recommended
- ARM64 or x86_64 architecture

## ⚙️ Configuration

### Lambda Memory Settings
You can adjust Lambda memory allocation in `cdk/env_config.py`:

```python
# Lambda memory size in MB
LAMBDA_MEMORY_SIZE = 1024     # 1GB
# LAMBDA_MEMORY_SIZE = 3008   # 3GB
# LAMBDA_MEMORY_SIZE = 5120   # 5GB
# LAMBDA_MEMORY_SIZE = 7168   # 7GB
# LAMBDA_MEMORY_SIZE = 10240  # 10GB
```

Higher memory allocation provides better performance but increases costs.

### API Parameters
The Lambda function accepts the following parameters:

```json
{
  "prompt": "User: Your question here\n\nAssistant:",
  "n_predict": 25,        // Number of tokens to generate
  "temperature": 0.7,     // Randomness (0.0-2.0)
  "top_p": 0.9,          // Nucleus sampling (0.0-1.0)
  "top_k": 40,           // Top-k sampling
  "repeat_penalty": 1.1   // Repetition penalty
}
```

## 🧪 Usage Examples

### AWS Lambda
```bash
# Deploy to AWS
./scripts/2-deploy-lambda.sh

# Test with our test script (recommended)
./scripts/3-test-lambda.sh

# Or test with AWS CLI directly
aws lambda invoke \
  --function-name bitnet-lambda-dev-function \
  --region us-east-1 \
  --payload '{"prompt":"User: Tell me a joke about programming.\n\nAssistant:","n_predict":25}' \
  response.json
```

## 🚀 Development Workflow

1. **Initialize**: `./scripts/1-initialize.sh`
2. **Deploy to AWS**: `./scripts/2-deploy-lambda.sh`
3. **Test**: `./scripts/3-test-lambda.sh`
4. **Monitor**: Check logs and performance

## 💰 Cost Considerations

Lambda pricing is based on:
- **Memory allocation**: Higher memory = higher cost per invocation
- **Execution time**: Charged per 100ms of execution
- **Cold starts**: First invocation may take 30-60 seconds
- **Container image size**: ~1.3GB image affects cold start time

Estimated costs (us-east-1):
- 1GB memory: ~$0.0000166667 per 100ms
- 10GB memory: ~$0.0001666667 per 100ms

## 🔧 Troubleshooting

### Common Issues
- **Cold start timeout**: First invocation may take 30-60 seconds
- **Memory errors**: Increase `LAMBDA_MEMORY_SIZE` in `cdk/env_config.py`
- **Container build fails**: Ensure 10GB+ free disk space
- **Permission errors**: Verify AWS CLI configuration and permissions

### Monitoring
- Check CloudWatch logs for detailed execution information
- Monitor Lambda metrics in AWS Console
- Use the enhanced deployment output for quick access to logs

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Microsoft BitNet](https://github.com/microsoft/BitNet) for 1-bit quantization research
- [llama.cpp](https://github.com/ggerganov/llama.cpp) for the inference engine

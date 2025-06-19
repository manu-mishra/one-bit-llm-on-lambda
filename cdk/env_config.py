"""
Environment configuration for BitNet Lambda deployment.
"""

# Application name - used as prefix for all resources
APP_NAME = "bitnet-lambda"

# Environment suffix - allows multiple deployments (dev, staging, prod, etc.)
ENV_SUFFIX = "dev"

# Lambda memory size in MB
#lets deploy againLAMBDA_MEMORY_SIZE = 1024     # 1GB
LAMBDA_MEMORY_SIZE = 2048   # 2GB
#LAMBDA_MEMORY_SIZE = 3008   # 3GB
#LAMBDA_MEMORY_SIZE = 5120   # 5GB
#LAMBDA_MEMORY_SIZE = 7168   # 7GB
#LAMBDA_MEMORY_SIZE = 10240  # 10GB

# Lambda Configuration
LAMBDA_CONFIG = {
    "memory_size": 10240,  # Memory in MB (10GB)
    "timeout_minutes": 15,  # Timeout in minutes
    "architecture": "ARM_64",  # ARM_64 or X86_64
    "threads": 4,  # Number of threads for BitNet inference
    "context_size": 2048,  # Context size for the model
}

def get_stack_name() -> str:
    """Get the CDK stack name."""
    return f"{APP_NAME}-{ENV_SUFFIX}-stack"

def get_resource_name(resource_type: str) -> str:
    """Get a resource name with consistent naming convention."""
    return f"{APP_NAME}-{ENV_SUFFIX}-{resource_type}"

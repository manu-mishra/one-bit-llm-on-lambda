from aws_cdk import (
    Stack,
    Duration,
    RemovalPolicy,
    CfnOutput,
    aws_lambda as lambda_,
    aws_iam as iam,
    aws_logs as logs,
    aws_ecr_assets as ecr_assets,
)
from constructs import Construct
from env_config import get_resource_name, APP_NAME, ENV_SUFFIX, LAMBDA_MEMORY_SIZE
import os

class CdkStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Build Docker image asset
        bitnet_image = ecr_assets.DockerImageAsset(
            self, "BitNetImage",
            directory=os.path.join(os.path.dirname(__file__), "..", ".."),
            file="app/Dockerfile.lambda",
            exclude=[
                "cdk/**",
                "cdk.out/**",
                ".git/**",
                "**/.git/**",
                "**/cdk.out/**",
                "**/__pycache__/**",
                "**/.venv/**",
                "**/node_modules/**"
            ]
        )

        # CloudWatch Log Group for Lambda
        log_group = logs.LogGroup(
            self, "LambdaLogGroup",
            log_group_name=f"/aws/lambda/{get_resource_name('function')}",
            removal_policy=RemovalPolicy.DESTROY,
            retention=logs.RetentionDays.INFINITE
        )

        # IAM Role for Lambda
        lambda_role = iam.Role(
            self, "LambdaExecutionRole",
            role_name=get_resource_name("lambda-role"),
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name("service-role/AWSLambdaBasicExecutionRole")
            ]
        )

        # Grant Lambda permission to write to CloudWatch Logs
        log_group.grant_write(lambda_role)

        # Lambda Function using the Docker image asset
        bitnet_function = lambda_.Function(
            self, "BitNetFunction",
            function_name=get_resource_name("function"),
            runtime=lambda_.Runtime.FROM_IMAGE,
            handler=lambda_.Handler.FROM_IMAGE,
            code=lambda_.Code.from_ecr_image(
                repository=bitnet_image.repository,
                tag_or_digest=bitnet_image.image_tag
            ),
            role=lambda_role,
            memory_size=LAMBDA_MEMORY_SIZE,  # Memory size from config
            timeout=Duration.minutes(15),
            architecture=lambda_.Architecture.ARM_64,  # Keep ARM64
            log_group=log_group,
            environment={
                "MODEL_PATH": "/app/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf",
                "CONTEXT_SIZE": "2048",
                "THREADS": "4"  # Increase threads for better performance with 10GB
            }
        )

        # Output the Lambda function details
        self.lambda_function_arn = bitnet_function.function_arn
        
        # CDK Outputs for deployment script
        CfnOutput(
            self, "FunctionName",
            value=bitnet_function.function_name,
            description="Lambda Function Name"
        )
        
        CfnOutput(
            self, "FunctionArn", 
            value=bitnet_function.function_arn,
            description="Lambda Function ARN"
        )
        
        CfnOutput(
            self, "LogGroupName",
            value=log_group.log_group_name,
            description="CloudWatch Log Group Name"
        )

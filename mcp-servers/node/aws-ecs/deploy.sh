#!/bin/bash

# MCP GitHub Reviewer Express.js Server - AWS ECS Deployment Script
# This script builds, pushes, and deploys the Express.js MCP server to AWS ECS

set -e

# Configuration
ENVIRONMENT=${1:-production}
REGION=${AWS_DEFAULT_REGION:-us-west-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STACK_NAME="mcp-github-reviewer-express-${ENVIRONMENT}"
ECR_REPOSITORY="mcp-github-reviewer-express"
IMAGE_TAG=${2:-latest}

echo "Deploying MCP GitHub Reviewer Express.js to AWS ECS"
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo "AWS Account: ${ACCOUNT_ID}"
echo "Stack Name: ${STACK_NAME}"

# Set up ECR repository
echo "Setting up ECR repository..."
aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${REGION} >/dev/null 2>&1 || {
    echo "Creating ECR repository: ${ECR_REPOSITORY}"
    aws ecr create-repository --repository-name ${ECR_REPOSITORY} --region ${REGION}
}

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build Docker image
echo "Building Docker image..."
docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} ..

# Tag image for ECR
docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

# Push image to ECR
echo "Pushing image to ECR..."
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."

# Get VPC and subnet information
echo "Getting VPC and subnet information..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${REGION})
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[0:2].SubnetId' --output text --region ${REGION} | tr '\t' ',')

echo "Using VPC: ${VPC_ID}"
echo "Using Subnets: ${SUBNET_IDS}"

# Deploy the stack
aws cloudformation deploy \
    --template-file cloudformation.yaml \
    --stack-name ${STACK_NAME} \
    --parameter-overrides \
        Environment=${ENVIRONMENT} \
        VpcId=${VPC_ID} \
        SubnetIds=${SUBNET_IDS} \
        ImageTag=${IMAGE_TAG} \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${REGION}

# Get stack outputs
echo "Getting stack outputs..."
LOAD_BALANCER_DNS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text \
    --region ${REGION})

LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
    --output text \
    --region ${REGION})

HEALTH_CHECK_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`HealthCheckURL`].OutputValue' \
    --output text \
    --region ${REGION})

echo ""
echo "Deployment completed successfully!"
echo "=================================="
echo "Load Balancer DNS: ${LOAD_BALANCER_DNS}"
echo "Load Balancer URL: ${LOAD_BALANCER_URL}"
echo "Health Check URL: ${HEALTH_CHECK_URL}"
echo ""
echo "You can test the deployment with:"
echo "curl ${HEALTH_CHECK_URL}"
echo ""
echo "To update the GitHub Actions workflow, use this URL as MCP_SERVER_URL:"
echo "${LOAD_BALANCER_URL}"
echo ""
echo "To monitor the deployment:"
echo "aws ecs describe-services --cluster mcp-github-reviewer-express-${ENVIRONMENT} --services mcp-github-reviewer-express-service-${ENVIRONMENT} --region ${REGION}"
echo ""
echo "To view logs:"
echo "aws logs tail /ecs/mcp-github-reviewer-express-${ENVIRONMENT} --follow --region ${REGION}"

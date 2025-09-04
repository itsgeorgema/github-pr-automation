#!/bin/bash

# AWS ECS Deployment Script for MCP GitHub Reviewer
# Usage: ./deploy.sh [environment] [region]

set -e

# Configuration
ENVIRONMENT=${1:-production}
REGION=${2:-us-west-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY="mcp-github-reviewer"
STACK_NAME="mcp-github-reviewer-${ENVIRONMENT}"

echo "Deploying MCP GitHub Reviewer to AWS ECS"
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo "AWS Account: ${AWS_ACCOUNT_ID}"
echo "Stack Name: ${STACK_NAME}"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Create ECR repository if it doesn't exist
echo "Setting up ECR repository..."
aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${REGION} > /dev/null 2>&1 || {
    echo "Creating ECR repository: ${ECR_REPOSITORY}"
    aws ecr create-repository --repository-name ${ECR_REPOSITORY} --region ${REGION}
}

# Get ECR login token
echo "Logging into ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build and push Docker image
echo "Building Docker image for linux/amd64..."
docker build --platform linux/amd64 -t ${ECR_REPOSITORY}:latest ..

# Tag and push to ECR
echo "Pushing image to ECR..."
docker tag ${ECR_REPOSITORY}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

# Create or update CloudFormation stack
echo "Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file cloudformation.yaml \
    --stack-name ${STACK_NAME} \
    --parameter-overrides \
        Environment=${ENVIRONMENT} \
        VpcId=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${REGION}) \
        SubnetIds=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${REGION})" --query 'Subnets[*].SubnetId' --output text --region ${REGION} | tr '\t' ',') \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${REGION}

# Get stack outputs
echo "Getting deployment information..."
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

echo "Deployment completed successfully!"
echo ""
echo "Deployment Information:"
echo "  Stack Name: ${STACK_NAME}"
echo "  Load Balancer DNS: ${LOAD_BALANCER_DNS}"
echo "  Load Balancer URL: ${LOAD_BALANCER_URL}"
echo "  Health Check: ${LOAD_BALANCER_URL}/health"
echo ""
echo "Next Steps:"
echo "  1. Update your GitHub repository secrets with:"
echo "     MCP_SERVER_URL=${LOAD_BALANCER_URL}"
echo "  2. Test the deployment:"
echo "     curl ${LOAD_BALANCER_URL}/health"
echo "  3. Monitor logs:"
echo "     aws logs tail /ecs/mcp-github-reviewer-${ENVIRONMENT} --follow --region ${REGION}"
echo ""
echo "MCP GitHub Reviewer is now running on AWS ECS!"

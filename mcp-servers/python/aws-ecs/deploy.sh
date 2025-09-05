#!/bin/bash

# AWS ECS Deployment Script for MCP GitHub Reviewer
# Usage: ./deploy.sh [environment] [region]

set -euo pipefail

trap 'echo "[error] Deployment failed (line $LINENO)" >&2' ERR

# Configuration / flags
ENVIRONMENT=${1:-production}
REGION=${2:-us-west-1}

# Optional behavior flags (default to fast-path optimizations)
FORCE_DEPLOY=${FORCE_DEPLOY:-false}
SKIP_BUILD_IF_EXISTS=${SKIP_BUILD_IF_EXISTS:-true}
SKIP_DEPLOY_IF_SAME_TAG=${SKIP_DEPLOY_IF_SAME_TAG:-true}

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY="mcp-github-reviewer"
STACK_NAME="mcp-github-reviewer-${ENVIRONMENT}"
IMAGE_TAG=${3:-latest}

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

require_jq() { command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }; }

image_exists_in_ecr() {
  aws ecr describe-images \
    --repository-name "${ECR_REPOSITORY}" \
    --image-ids imageTag="${IMAGE_TAG}" \
    --region "${REGION}" >/dev/null 2>&1
}

current_stack_image_tag() {
  aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${REGION}" \
    --query 'Stacks[0].Parameters[?ParameterKey==`ImageTag`].ParameterValue' \
    --output text 2>/dev/null || true
}

# Create ECR repository if it doesn't exist
echo "Setting up ECR repository..."
aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${REGION} > /dev/null 2>&1 || {
    echo "Creating ECR repository: ${ECR_REPOSITORY}"
    aws ecr create-repository --repository-name ${ECR_REPOSITORY} --region ${REGION}
}

# Build & push image (skip when possible)
DO_BUILD_PUSH=true
if ${SKIP_BUILD_IF_EXISTS} && image_exists_in_ecr; then
  echo "Image ${ECR_REPOSITORY}:${IMAGE_TAG} already exists in ECR. Skipping build/push."
  DO_BUILD_PUSH=false
fi

if ${DO_BUILD_PUSH}; then
  echo "Logging into ECR..."
  aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

  echo "Building Docker image for linux/amd64..."
  docker build --platform linux/amd64 -t ${ECR_REPOSITORY}:${IMAGE_TAG} ..

  echo "Tagging image..."
  docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

  echo "Pushing image to ECR..."
  docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}
fi

# Create or update CloudFormation stack
echo "Deploying CloudFormation stack..."
DO_DEPLOY=true
EXISTING_TAG=$(current_stack_image_tag || true)
if ${SKIP_DEPLOY_IF_SAME_TAG} && [[ "${EXISTING_TAG}" == "${IMAGE_TAG}" ]] && [[ "${FORCE_DEPLOY}" != true ]]; then
  echo "Stack already uses ImageTag=${IMAGE_TAG}. Skipping CloudFormation deploy."
  DO_DEPLOY=false
fi

if ${DO_DEPLOY}; then
  aws cloudformation deploy \
      --template-file cloudformation.yaml \
      --stack-name ${STACK_NAME} \
      --parameter-overrides \
          Environment=${ENVIRONMENT} \
          VpcId=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${REGION}) \
          SubnetIds=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${REGION})" --query 'Subnets[*].SubnetId' --output text --region ${REGION} | tr '\t' ',') \
          ImageTag=${IMAGE_TAG} \
      --capabilities CAPABILITY_NAMED_IAM \
      --no-fail-on-empty-changeset \
      --region ${REGION}
fi

echo "Getting deployment information..."
STACK_OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${REGION} \
    --query 'Stacks[0].Outputs' \
    --output json)

get_output() {
  local key=$1
  echo "${STACK_OUTPUTS}" | jq -r ".[] | select(.OutputKey==\"${key}\").OutputValue" | sed 's/null//'
}

LOAD_BALANCER_DNS=$(get_output LoadBalancerDNS)
LOAD_BALANCER_URL=$(get_output LoadBalancerURL)
CLUSTER_NAME=$(get_output ClusterName)
SERVICE_NAME=$(get_output ServiceName)

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

# Force a new deployment to refresh tasks to the latest image when using mutable tags
if [[ -n "${CLUSTER_NAME}" && -n "${SERVICE_NAME}" ]]; then
  echo "Forcing new ECS deployment for service: ${SERVICE_NAME} (cluster: ${CLUSTER_NAME})"
  aws ecs update-service \
    --cluster "${CLUSTER_NAME}" \
    --service "${SERVICE_NAME}" \
    --force-new-deployment \
    --region "${REGION}" >/dev/null
fi
echo ""
echo "MCP GitHub Reviewer is now running on AWS ECS!"

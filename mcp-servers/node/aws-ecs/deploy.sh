#!/bin/bash

# MCP GitHub Reviewer Express.js Server - AWS ECS Deployment Script
# This script builds, pushes, and deploys the Express.js MCP server to AWS ECS

set -euo pipefail

trap 'echo "[error] Deployment failed (line $LINENO)" >&2' ERR

# Configuration / flags
ENVIRONMENT=${1:-production}
REGION=${AWS_DEFAULT_REGION:-us-west-1}
IMAGE_TAG=${2:-latest}

# Optional behavior flags (default to fast-path optimizations)
FORCE_DEPLOY=${FORCE_DEPLOY:-false}
SKIP_BUILD_IF_EXISTS=${SKIP_BUILD_IF_EXISTS:-true}
SKIP_DEPLOY_IF_SAME_TAG=${SKIP_DEPLOY_IF_SAME_TAG:-true}

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STACK_NAME="mcp-github-reviewer-express-${ENVIRONMENT}"
ECR_REPOSITORY="mcp-github-reviewer-express"

echo "Deploying MCP GitHub Reviewer Express.js to AWS ECS"
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo "AWS Account: ${ACCOUNT_ID}"
echo "Stack Name: ${STACK_NAME}"

# Helpers
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

# Set up ECR repository
echo "Setting up ECR repository..."
aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${REGION} >/dev/null 2>&1 || {
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
  aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

  echo "Building Docker image for linux/amd64..."
  docker build --platform linux/amd64 -t ${ECR_REPOSITORY}:${IMAGE_TAG} ..

  echo "Tagging image..."
  docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

  echo "Pushing image to ECR..."
  docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}
fi

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."

# Get VPC and subnet information
echo "Getting VPC and subnet information..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${REGION})
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[0:2].SubnetId' --output text --region ${REGION} | tr '\t' ',')

echo "Using VPC: ${VPC_ID}"
echo "Using Subnets: ${SUBNET_IDS}"

# Decide whether CFN deploy is necessary
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
          VpcId=${VPC_ID} \
          SubnetIds=${SUBNET_IDS} \
          ImageTag=${IMAGE_TAG} \
      --capabilities CAPABILITY_NAMED_IAM \
      --no-fail-on-empty-changeset \
      --region ${REGION}
fi

echo "Getting stack outputs..."
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

# Derive health check URL if not exported by the template
HEALTH_CHECK_URL="${LOAD_BALANCER_URL%/}/health"

# Force a new deployment to ensure the latest image is pulled when using mutable tags (e.g., latest)
if [[ -n "${CLUSTER_NAME}" && -n "${SERVICE_NAME}" ]]; then
  echo "Forcing new ECS deployment for service: ${SERVICE_NAME} (cluster: ${CLUSTER_NAME})"
  aws ecs update-service \
    --cluster "${CLUSTER_NAME}" \
    --service "${SERVICE_NAME}" \
    --force-new-deployment \
    --region "${REGION}" >/dev/null
else
  echo "Warning: Could not resolve ClusterName/ServiceName from stack outputs. Skipping force deployment."
fi

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
if [[ -n "${CLUSTER_NAME}" && -n "${SERVICE_NAME}" ]]; then
  echo "aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --region ${REGION}"
fi
echo ""
echo "To view logs:"
echo "aws logs tail /ecs/mcp-express-${ENVIRONMENT} --follow --region ${REGION}"

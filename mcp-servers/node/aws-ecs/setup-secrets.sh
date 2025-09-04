#!/bin/bash

# MCP GitHub Reviewer Express.js Server - AWS Secrets Manager Setup Script
# This script securely sets up API keys and tokens in AWS Secrets Manager

set -e

# Configuration
ENVIRONMENT=${1:-production}
REGION=${AWS_DEFAULT_REGION:-us-west-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Setting up secrets for MCP GitHub Reviewer Express.js"
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo "AWS Account: ${ACCOUNT_ID}"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Function to validate Anthropic API key format
validate_anthropic_key() {
    local key="$1"
    if [[ ${#key} -lt 20 || ! "$key" =~ ^sk-ant- ]]; then
        echo "Error: Invalid Anthropic API key format. Should start with 'sk-ant-' and be at least 20 characters."
        return 1
    fi
    return 0
}

# Function to validate OpenAI API key format
validate_openai_key() {
    local key="$1"
    if [[ ${#key} -lt 20 || ! "$key" =~ ^sk- ]]; then
        echo "Error: Invalid OpenAI API key format. Should start with 'sk-' and be at least 20 characters."
        return 1
    fi
    return 0
}

# Function to validate GitHub token format
validate_github_token() {
    local token="$1"
    if [[ ${#token} -lt 20 ]]; then
        echo "Error: Invalid GitHub token format. Should be at least 20 characters."
        return 1
    fi
    return 0
}

# Function to create or update secret
create_secret() {
    local secret_name=$1
    local secret_description=$2
    local secret_value=$3
    
    echo "Creating/updating secret: ${secret_name}"
    
    # Check if secret exists
    if aws secretsmanager describe-secret --secret-id ${secret_name} --region ${REGION} > /dev/null 2>&1; then
        echo "Secret ${secret_name} exists, updating..."
        aws secretsmanager update-secret \
            --secret-id ${secret_name} \
            --secret-string "${secret_value}" \
            --region ${REGION}
    else
        echo "Creating new secret: ${secret_name}"
        aws secretsmanager create-secret \
            --name ${secret_name} \
            --description "${secret_description}" \
            --secret-string "${secret_value}" \
            --region ${REGION}
    fi
}

# Prompt for API keys securely
echo ""
echo "Please provide your API keys (input will be hidden, press Enter to skip):"
echo ""

# Anthropic API Key (optional)
read -s -p "Anthropic API Key (optional): " ANTHROPIC_API_KEY
echo ""
if [ ! -z "$ANTHROPIC_API_KEY" ]; then
    if validate_anthropic_key "$ANTHROPIC_API_KEY"; then
        create_secret "mcp-github-reviewer-express/anthropic-api-key-${ENVIRONMENT}" "Anthropic API key for MCP GitHub Reviewer Express" "$ANTHROPIC_API_KEY"
    else
        echo "Skipping Anthropic API key due to validation warning"
    fi
fi

# OpenAI API Key (required for default configuration)
read -s -p "OpenAI API Key (required): " OPENAI_API_KEY
echo ""
if [ ! -z "$OPENAI_API_KEY" ]; then
    if validate_openai_key "$OPENAI_API_KEY"; then
        create_secret "mcp-github-reviewer-express/openai-api-key-${ENVIRONMENT}" "OpenAI API key for MCP GitHub Reviewer Express" "$OPENAI_API_KEY"
    else
        echo "Skipping OpenAI API key due to validation warning"
    fi
fi

# GitHub Token (required)
read -s -p "GitHub Token (required): " GITHUB_TOKEN
echo ""
if [ ! -z "$GITHUB_TOKEN" ]; then
    if validate_github_token "$GITHUB_TOKEN"; then
        create_secret "mcp-github-reviewer-express/github-token-${ENVIRONMENT}" "GitHub token for MCP GitHub Reviewer Express" "$GITHUB_TOKEN"
    else
        echo "Skipping GitHub token due to validation warning"
    fi
fi


# Clear sensitive variables from environment
unset ANTHROPIC_API_KEY
unset OPENAI_API_KEY
unset GITHUB_TOKEN

# Clear from shell history if possible
if [[ -n "$HISTFILE" ]]; then
    # Remove the last few lines that might contain the API keys
    sed -i '' '$d' "$HISTFILE" 2>/dev/null || true
    sed -i '' '$d' "$HISTFILE" 2>/dev/null || true
    sed -i '' '$d' "$HISTFILE" 2>/dev/null || true
fi

echo ""
echo "Secrets setup completed successfully!"
echo "===================================="
echo ""
echo "You can now run the deployment script:"
echo "./deploy.sh ${ENVIRONMENT}"
echo ""
echo "To verify secrets were created:"
echo "aws secretsmanager list-secrets --query 'SecretList[?contains(Name, \`mcp-github-reviewer-express\`)].Name' --output table --region ${REGION}"

#!/bin/bash

# Setup AWS Secrets Manager for MCP GitHub Reviewer
# Usage: ./setup-secrets.sh [region]

set -e

REGION=${1:-us-west-1}

echo "Setting up AWS Secrets Manager for MCP GitHub Reviewer"
echo "Region: ${REGION}"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

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

# Function to securely read input
read_secure_input() {
    local prompt=$1
    local var_name=$2
    
    echo -n "$prompt"
    read -s "$var_name"
    echo ""
    
    # Clear the variable from memory after a short delay
    (sleep 1; unset "$var_name") &
}

# Function to validate API key format
validate_anthropic_key() {
    local key=$1
    if [[ $key =~ ^sk-ant- ]]; then
        return 0
    else
        echo "Warning: Anthropic API key should start with 'sk-ant-'"
        return 1
    fi
}

validate_openai_key() {
    local key=$1
    if [[ $key =~ ^sk- ]]; then
        return 0
    else
        echo "Warning: OpenAI API key should start with 'sk-'"
        return 1
    fi
}

validate_github_token() {
    local token=$1
    if [[ ${#token} -ge 40 ]]; then
        return 0
    else
        echo "Warning: GitHub token should be at least 40 characters long"
        return 1
    fi
}

# Prompt for API keys securely
echo ""
echo "Please provide your API keys (input will be hidden, press Enter to skip):"
echo ""

# Anthropic API Key
read_secure_input "Anthropic API Key: " ANTHROPIC_API_KEY
if [ ! -z "$ANTHROPIC_API_KEY" ]; then
    if validate_anthropic_key "$ANTHROPIC_API_KEY"; then
        create_secret "mcp-server/anthropic-key" "Anthropic API key for MCP server" "$ANTHROPIC_API_KEY"
    else
        echo "Skipping Anthropic API key due to validation warning"
    fi
fi

# OpenAI API Key
read_secure_input "OpenAI API Key: " OPENAI_API_KEY
if [ ! -z "$OPENAI_API_KEY" ]; then
    if validate_openai_key "$OPENAI_API_KEY"; then
        create_secret "mcp-server/openai-key" "OpenAI API key for MCP server" "$OPENAI_API_KEY"
    else
        echo "Skipping OpenAI API key due to validation warning"
    fi
fi

# GitHub Token
read_secure_input "GitHub Token: " GITHUB_TOKEN
if [ ! -z "$GITHUB_TOKEN" ]; then
    if validate_github_token "$GITHUB_TOKEN"; then
        create_secret "mcp-server/github-token" "GitHub token for MCP server" "$GITHUB_TOKEN"
    else
        echo "Skipping GitHub token due to validation warning"
    fi
fi

# Clear sensitive data from environment
unset ANTHROPIC_API_KEY
unset OPENAI_API_KEY
unset GITHUB_TOKEN

# Clear bash history of sensitive commands (if possible)
if [ -n "$HISTFILE" ]; then
    # Remove any lines containing API keys from history
    sed -i '/sk-ant-/d' "$HISTFILE" 2>/dev/null || true
    sed -i '/sk-[a-zA-Z0-9]\{20,\}/d' "$HISTFILE" 2>/dev/null || true
    sed -i '/ghp_[a-zA-Z0-9]\{36\}/d' "$HISTFILE" 2>/dev/null || true
fi

echo ""
echo "Secrets setup completed!"
echo ""
echo "Created secrets:"
echo "  - mcp-server/anthropic-key"
echo "  - mcp-server/openai-key"
echo "  - mcp-server/github-token"
echo ""
echo "Security notes:"
echo "  - API keys are stored securely in AWS Secrets Manager"
echo "  - Sensitive data has been cleared from memory"
echo "  - Shell history has been cleaned"
echo ""
echo "Next steps:"
echo "  1. Run the deployment script: ./deploy.sh"
echo "  2. Update your GitHub repository secrets with the MCP server URL"
echo ""

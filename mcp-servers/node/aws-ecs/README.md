# MCP GitHub Reviewer Express.js - AWS ECS Deployment

This directory contains all the necessary files to deploy the Express.js MCP server to AWS ECS using CloudFormation.

## Files

- [`cloudformation.yaml`](./cloudformation.yaml) - CloudFormation template for ECS infrastructure
- [`task-definition.json`](./task-definition.json) - ECS task definition template
- [`service-definition.json`](./service-definition.json) - ECS service definition template
- [`deploy.sh`](./deploy.sh) - Automated deployment script
- [`setup-secrets.sh`](./setup-secrets.sh) - Secure secrets setup script
- [`README.md`](./README.md) - This documentation

## Quick Start

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Docker** installed and running
3. **API Keys** for OpenAI and GitHub (Anthropic optional)

### 1. Set Up Secrets

First, securely store your API keys in AWS Secrets Manager:

```bash
# Set up secrets for production environment
./setup-secrets.sh production

# Or for development environment
./setup-secrets.sh development
```

This script will:
- Prompt for your API keys securely (hidden input)
- Allow you to skip optional keys (press Enter to skip)
- Validate key formats
- Store only the provided keys in AWS Secrets Manager
- Clear sensitive data from shell history

**Required for default configuration:**
- OpenAI API key
- GitHub token

**Optional:**
- Anthropic API key (only needed if you want to use Claude instead of GPT)

### 2. Deploy to ECS

Deploy the Express.js server to AWS ECS:

```bash
# Deploy to production
./deploy.sh production

# Deploy to development with specific image tag
./deploy.sh development v1.0.0
```

This script will:
- Build the Docker image
- Push to ECR
- Deploy CloudFormation stack
- Set up load balancer and ECS service
- Display deployment URLs

## Infrastructure

The CloudFormation template creates:

### Core Resources
- **ECS Cluster** - Fargate cluster for running containers
- **ECR Repository** - For storing Docker images
- **Application Load Balancer** - Public-facing load balancer
- **Target Group** - Routes traffic to ECS tasks

### Security
- **Security Groups** - Control network access
- **IAM Roles** - Task execution and task roles
- **Secrets Manager** - Secure API key storage

### Monitoring
- **CloudWatch Logs** - Application logging
- **Health Checks** - Container and load balancer health monitoring

## Configuration

### Environment Variables

The container uses these environment variables:

- `NODE_ENV` - Node.js environment (production/staging/development)
- `PORT` - Server port (default: 8000)
- `AI_PROVIDER` - AI provider preference (default: openai)

### Secrets

Secrets are automatically injected from AWS Secrets Manager:

- `OPENAI_API_KEY` - OpenAI GPT API key (required for default configuration)
- `GITHUB_TOKEN` - GitHub Personal Access Token (required)
- `ANTHROPIC_API_KEY` - Anthropic Claude API key (optional - only needed if AI_PROVIDER=anthropic)

## Monitoring

### Health Check

The service includes a health check endpoint:

```bash
curl http://your-load-balancer-url/health
```

### View Logs

```bash
# Follow logs in real-time
aws logs tail /ecs/mcp-github-reviewer-express-production --follow --region us-west-1

# View recent logs
aws logs tail /ecs/mcp-github-reviewer-express-production --region us-west-1
```

### Check Service Status

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster mcp-github-reviewer-express-production \
  --services mcp-github-reviewer-express-service-production \
  --region us-west-1
```

## Updates

### Update Application

To update the application:

1. Make your code changes
2. Run the deployment script with a new image tag:

```bash
./deploy.sh production v1.1.0
```

### Update Secrets

To update API keys:

```bash
./setup-secrets.sh production
```

## Cleanup

### Delete Stack

To remove all resources:

```bash
aws cloudformation delete-stack \
  --stack-name mcp-github-reviewer-express-production \
  --region us-west-1
```

### Delete ECR Repository

```bash
aws ecr delete-repository \
  --repository-name mcp-github-reviewer-express \
  --force \
  --region us-west-1
```

## Security

### IAM Permissions

The deployment requires these AWS permissions:

- **ECR**: Full access for image management
- **ECS**: Full access for cluster and service management
- **EC2**: VPC, subnet, and security group management
- **IAM**: Role creation and policy management
- **Secrets Manager**: Full access for secret management
- **CloudFormation**: Full access for stack management
- **CloudWatch Logs**: Log group creation and management

### Network Security

- Load balancer is internet-facing
- ECS tasks run in private subnets with public IP assignment
- Security groups restrict traffic to necessary ports only
- Health checks ensure only healthy containers receive traffic

## Troubleshooting

### Common Issues

1. **Deployment fails with "AccessDenied"**
   - Ensure your AWS credentials have sufficient permissions
   - Check that the ECS service-linked role exists

2. **Container fails to start**
   - Check CloudWatch logs for error messages
   - Verify secrets are properly configured
   - Ensure all required environment variables are set

3. **Health check failures**
   - Verify the application is listening on port 8000
   - Check that the `/health` endpoint is responding
   - Review security group rules

4. **Load balancer not accessible**
   - Check that the target group is healthy
   - Verify security group allows traffic on port 80
   - Ensure the ECS service is running

### Debug Commands

```bash
# Check stack events
aws cloudformation describe-stack-events \
  --stack-name mcp-github-reviewer-express-production \
  --region us-west-1

# Check ECS task details
aws ecs list-tasks \
  --cluster mcp-github-reviewer-express-production \
  --region us-west-1

# Check load balancer target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names mcp-github-reviewer-express-tg-production \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region us-west-1) \
  --region us-west-1
```

## GitHub Actions Integration

After deployment, update your GitHub Actions workflow to use the deployed MCP server:

```yaml
- name: Run AI Analysis
  env:
    MCP_SERVER_URL: http://your-load-balancer-url
  run: |
    # Your existing analysis script
```

## Express.js vs Python

Both Express.js and Python FastAPI versions are available:

| Feature | Express.js | Python FastAPI |
|---------|------------|----------------|
| **Runtime** | Node.js 18 | Python 3.11 |
| **Memory** | 1GB | 1GB |
| **CPU** | 0.5 vCPU | 0.5 vCPU |
| **Cold Start** | Faster | Slower |
| **Dependencies** | Smaller | Larger |
| **Type Safety** | TypeScript | Pydantic |
| **Default AI Provider** | OpenAI | OpenAI |

Choose based on your team's expertise and preferences.

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review CloudWatch logs for error details
3. Verify all prerequisites are met
4. Ensure AWS permissions are correctly configured

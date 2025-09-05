# AWS ECS Deployment for MCP GitHub Reviewer

This directory contains all the necessary files to deploy the MCP GitHub
Reviewer FastAPI server to AWS ECS using Fargate.

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Docker** installed and running
3. **API Keys** for Anthropic and/or OpenAI
4. **GitHub Token** for repository access

## Quick Start

### 1. Setup Secrets

First, store your API keys in AWS Secrets Manager:

```bash
cd mcp-servers/python/aws-ecs
./setup-secrets.sh
```

This will prompt you for your API keys and store them securely in AWS Secrets
Manager.

### 2. Deploy to ECS

Deploy the complete infrastructure:

```bash
./deploy.sh [environment] [region]
```

Examples:

```bash
# Deploy to production in us-west-1
./deploy.sh production us-west-1

# Deploy to development in us-west-1
./deploy.sh development us-west-1
```

### 3. Update GitHub Repository

After deployment, update your GitHub repository secrets:

1. Go to your repository settings
2. Navigate to Secrets and variables > Actions
3. Add/update the following secret:
   - `MCP_SERVER_URL`: The Load Balancer URL from deployment output

## Architecture

The deployment creates:

- **ECS Cluster** with Fargate launch type
- **Application Load Balancer** for external access
- **Target Group** for health checks
- **Security Groups** for network access
- **IAM Roles** for task execution and permissions
- **CloudWatch Logs** for monitoring
- **Secrets Manager** integration for API keys

## Files

- `cloudformation.yaml` - Complete AWS infrastructure definition
- `task-definition.json` - ECS task configuration
- `service-definition.json` - ECS service configuration
- `deploy.sh` - Automated deployment script
- `setup-secrets.sh` - Secrets management script
- `README.md` - This documentation

## Configuration

### Environment Variables

The following environment variables are configured:

- `AI_PROVIDER`: Set to "openai" by default (change based on your model)
- `PORT`: Set to 8000
- `HOST`: Set to 0.0.0.0

### Secrets

The following secrets are pulled from AWS Secrets Manager:

- `ANTHROPIC_API_KEY`: Your Anthropic API key
- `OPENAI_API_KEY`: Your OpenAI API key
- `GITHUB_TOKEN`: Your GitHub token

### Resource Allocation

- **CPU**: 512 units (0.5 vCPU)
- **Memory**: 1024 MB (1 GB)
- **Desired Count**: 1 instance

## Monitoring

### Health Checks

- **Path**: `/health`
- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Retries**: 3

### Logs

View logs using AWS CLI:

```bash
aws logs tail /ecs/mcp-github-reviewer-production --follow --region us-west-1
```

Or through the AWS Console:

1. Go to CloudWatch > Log groups
2. Find `/ecs/mcp-github-reviewer-{environment}`
3. View log streams

## Scaling

### Manual Scaling

Update the desired count:

```bash
aws ecs update-service \
    --cluster mcp-cluster-production \
    --service mcp-github-reviewer-service-production \
    --desired-count 2
```

### Auto Scaling

To enable auto scaling, you can add CloudWatch alarms and ECS auto scaling
policies to the CloudFormation template.

## Troubleshooting

### Common Issues

1. **Task fails to start**
   - Check CloudWatch logs for errors
   - Verify secrets are properly configured
   - Ensure security groups allow traffic

2. **Health check failures**
   - Verify the application is listening on port 8000
   - Check that `/health` endpoint returns 200
   - Review security group rules

3. **API key errors**
   - Verify secrets are stored in Secrets Manager
   - Check IAM permissions for task execution role
   - Ensure secret ARNs are correct in task definition

### Debug Commands

```bash
# Check service status
aws ecs describe-services \
    --cluster mcp-cluster-production \
    --services mcp-github-reviewer-service-production

# Check task status
aws ecs list-tasks \
    --cluster mcp-cluster-production \
    --service-name mcp-github-reviewer-service-production

# Get task details
aws ecs describe-tasks \
    --cluster mcp-cluster-production \
    --tasks TASK_ARN
```

## Cost Optimization

### Fargate Spot

The CloudFormation template includes Fargate Spot capacity provider for cost
savings. To use Spot instances:

```bash
aws ecs update-service \
    --cluster mcp-cluster-production \
    --service mcp-github-reviewer-service-production \
    --capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=1
```

### Resource Right-sizing

Monitor CloudWatch metrics and adjust CPU/memory allocation based on actual
usage.

## Security

### Network Security

- Application Load Balancer handles external traffic
- Security groups restrict access to necessary ports only
- Tasks run in private subnets with NAT gateway access

### Secrets Management

- API keys stored in AWS Secrets Manager
- IAM roles with minimal required permissions
- No secrets in container images or environment variables

### Encryption

- Secrets encrypted at rest in Secrets Manager
- Traffic encrypted in transit via HTTPS (when configured)

## Cleanup

To remove all resources:

```bash
aws cloudformation delete-stack --stack-name mcp-github-reviewer-production
```

Note: This will not delete the ECR repository or secrets. Remove those manually
if needed.

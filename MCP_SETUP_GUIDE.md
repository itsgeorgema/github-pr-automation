# MCP Server Setup Guide for Watchdog

This guide walks you through setting up a Model Context Protocol (MCP) server to enable AI-powered code reviews for multi-language projects (JavaScript/TypeScript, Python, Java, C++, SQL) in your Watchdog workflow.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [MCP Server Setup](#mcp-server-setup)
- [GitHub Integration](#github-integration)
- [Configuration](#configuration)
- [Testing](#testing)
- [Deployment Options](#deployment-options)
- [Troubleshooting](#troubleshooting)

## Overview

The MCP server acts as a bridge between your GitHub Actions workflow and AI models (like Claude, GPT-4, etc.) to provide intelligent multi-language code reviews. It receives PR diffs and metadata from JavaScript/TypeScript, Python, Java, C++, and SQL files, processes them through AI models with language-specific context, and posts comprehensive review comments back to GitHub.

### Architecture

```
Multi-Language PR → GitHub Actions → Language Detection → MCP Server → AI Model → Language-Specific Analysis → GitHub Comment
```

## Prerequisites

- Node.js 18+ or Python 3.11+
- GitHub repository with Actions enabled
- Access to an AI model API (OpenAI, Anthropic, etc.)
- A server/hosting platform (optional for local development)

## MCP Server Setup

### Option 1: Python MCP Server

#### 1. Copy Server Files

Copy the Python MCP server files from the `mcp-servers/python/` directory:

```bash
cp -r mcp-servers/python/ mcp-github-reviewer/
cd mcp-github-reviewer
```

**Server Files:**
- [`main.py`](mcp-servers/python/main.py) - FastAPI server implementation
- [`requirements.txt`](mcp-servers/python/requirements.txt) - Python dependencies
- [`Dockerfile`](mcp-servers/python/Dockerfile) - Docker container configuration
- [`env.example`](mcp-servers/python/env.example) - Environment variables template

#### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

#### 3. Configure Environment

```bash
cp env.example .env
# Edit .env with your API keys
```

#### 4. Run the Server

```bash
python main.py
```

The server files are located in `mcp-servers/python/` and include:
- [`main.py`](mcp-servers/python/main.py) - Main server application
- [`requirements.txt`](mcp-servers/python/requirements.txt) - Python dependencies
- [`Dockerfile`](mcp-servers/python/Dockerfile) - Docker configuration
- [`docker-compose.yml`](mcp-servers/python/docker-compose.yml) - Docker Compose configuration
- [`env.example`](mcp-servers/python/env.example) - Environment variables template
- [`.gitignore`](mcp-servers/python/.gitignore) - Git ignore file
- [`README.md`](mcp-servers/python/README.md) - Quick start guide





### Option 2: Node.js MCP Server

#### 1. Copy Server Files

Copy the Node.js MCP server files from the `mcp-servers/node/` directory:

```bash
cp -r mcp-servers/node/ mcp-github-reviewer-js/
cd mcp-github-reviewer-js
```

**Server Files:**
- [`src/server.ts`](mcp-servers/node/src/server.ts) - Express.js server implementation
- [`package.json`](mcp-servers/node/package.json) - Node.js dependencies and scripts
- [`tsconfig.json`](mcp-servers/node/tsconfig.json) - TypeScript configuration
- [`Dockerfile`](mcp-servers/node/Dockerfile) - Docker container configuration
- [`env.example`](mcp-servers/node/env.example) - Environment variables template

#### 2. Install Dependencies

```bash
npm install
```

#### 3. Configure Environment

```bash
cp env.example .env
# Edit .env with your API keys
```

#### 4. Build and Run

```bash
npm run build
npm start
```

#### 5. Development Mode

```bash
npm run dev
```

The server files are located in `mcp-servers/node/` and include:
- [`src/server.ts`](mcp-servers/node/src/server.ts) - Main server application
- [`package.json`](mcp-servers/node/package.json) - Node.js dependencies and scripts
- [`tsconfig.json`](mcp-servers/node/tsconfig.json) - TypeScript configuration
- [`Dockerfile`](mcp-servers/node/Dockerfile) - Docker configuration
- [`docker-compose.yml`](mcp-servers/node/docker-compose.yml) - Docker Compose configuration
- [`env.example`](mcp-servers/node/env.example) - Environment variables template
- [`.gitignore`](mcp-servers/node/.gitignore) - Git ignore file
- [`README.md`](mcp-servers/node/README.md) - Quick start guide



## GitHub Integration

### 1. Update GitHub Actions Workflow

Replace the MCP client script in your GitHub Actions workflow with a call to your MCP server:

```yaml
- name: Call MCP Server for AI Review
  run: |
    curl -X POST "${{ secrets.MCP_SERVER_URL }}/analyze-pr" \
      -H "Content-Type: application/json" \
      -d '{
        "pr_number": ${{ steps.pr-info.outputs.pr-number }},
        "pr_title": "${{ steps.pr-info.outputs.pr-title }}",
        "pr_body": "${{ steps.pr-info.outputs.pr-body }}",
        "pr_author": "${{ steps.pr-info.outputs.pr-author }}",
        "changed_files": ["${{ steps.changed-files.outputs.files }}"],
        "diff_content": "'"$(cat /tmp/pr-analysis/full-diff.patch)"'",
        "repository": "${{ github.repository }}",
        "github_token": "${{ secrets.GITHUB_TOKEN }}"
      }'
```

### 2. Required GitHub Secrets

Add these secrets to your GitHub repository:

- `MCP_SERVER_URL`: URL of your deployed MCP server
- `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`: Your AI provider API key

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `AI_PROVIDER` | AI provider (`anthropic` or `openai`) | Yes |
| `ANTHROPIC_API_KEY` | Anthropic API key | If using Anthropic |
| `OPENAI_API_KEY` | OpenAI API key | If using OpenAI |
| `GITHUB_TOKEN` | GitHub token for API access | Yes |
| `PORT` | Server port (default: 8000) | No |

### Customization Options

1. **AI Model Selection**: Change the model in the API calls
2. **Review Criteria**: Modify the prompt to focus on specific aspects
3. **Response Format**: Customize the output format and structure
4. **Integration Points**: Add webhooks, databases, or other integrations

## Deployment Options

### 1. Local Development

```bash
# Python
python main.py

# Node.js
npm run dev
```

### 2. AWS ECS Deployment

Both Python and Node.js servers can be deployed to AWS ECS with Fargate for production use:

#### Python FastAPI Server

**Deployment Files:**
- [`cloudformation.yaml`](mcp-servers/python/aws-ecs/cloudformation.yaml) - AWS infrastructure template
- [`deploy.sh`](mcp-servers/python/aws-ecs/deploy.sh) - Automated deployment script
- [`setup-secrets.sh`](mcp-servers/python/aws-ecs/setup-secrets.sh) - Secure secrets setup
- [`README.md`](mcp-servers/python/aws-ecs/README.md) - Complete deployment guide

**Quick Deploy:**
```bash
cd mcp-servers/python/aws-ecs
./setup-secrets.sh production
./deploy.sh production
```

#### Node.js Express Server

**Deployment Files:**
- [`cloudformation.yaml`](mcp-servers/node/aws-ecs/cloudformation.yaml) - AWS infrastructure template
- [`deploy.sh`](mcp-servers/node/aws-ecs/deploy.sh) - Automated deployment script
- [`setup-secrets.sh`](mcp-servers/node/aws-ecs/setup-secrets.sh) - Secure secrets setup
- [`README.md`](mcp-servers/node/aws-ecs/README.md) - Complete deployment guide

**Quick Deploy:**
```bash
cd mcp-servers/node/aws-ecs
./setup-secrets.sh production
./deploy.sh production
```

### 2. Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["python", "main.py"]
```

### 3. Cloud Platforms

- **Heroku**: `git push heroku main`
- **Railway**: Connect GitHub repo
- **Vercel**: Deploy serverless functions
- **AWS Lambda**: Use serverless framework
- **Google Cloud Run**: Deploy containerized app

### 4. Self-hosted

Deploy on your own server with reverse proxy (nginx) and process manager (PM2, systemd).

## Testing

### 1. Health Check

```bash
curl http://localhost:8000/health
```

### 2. Test PR Analysis

```bash
curl -X POST http://localhost:8000/analyze-pr \
  -H "Content-Type: application/json" \
  -d '{
    "pr_number": 1,
    "pr_title": "Test PR",
    "pr_body": "Test description",
    "pr_author": "testuser",
    "changed_files": ["test.js"],
    "diff_content": "+console.log(\"hello\");",
    "repository": "owner/repo",
    "github_token": "your_token"
  }'
```

### 3. Integration Test

Create a test PR in your repository to verify the full workflow.

## Troubleshooting

### Common Issues

1. **API Rate Limits**: Implement rate limiting and retries
2. **Large Diffs**: Truncate or summarize large diffs before sending to AI
3. **Token Limits**: Split large requests into smaller chunks
4. **Network Timeouts**: Increase timeout values and add retry logic

### Debugging

1. Enable detailed logging
2. Check GitHub Actions logs
3. Monitor MCP server logs
4. Verify API key permissions
5. Test individual components separately

### Performance Optimization

1. Cache AI responses for similar code patterns
2. Use streaming responses for large reviews
3. Implement request queuing for high volume
4. Optimize prompt length and structure

## Advanced Features

### 1. Multi-Language Rule Engine

Add language-specific custom rules and checks:

```python
# Language-specific rule configuration
LANGUAGE_RULES = {
    'python': {
        'security_focus': ['sql_injection', 'xss', 'path_traversal'],
        'performance_checks': ['n_plus_one_queries', 'memory_leaks'],
        'style_guides': ['pep8', 'google', 'black']
    },
    'java': {
        'security_focus': ['injection', 'deserialization', 'xxe'],
        'performance_checks': ['memory_management', 'thread_safety'],
        'style_guides': ['google', 'oracle', 'spring']
    },
    'cpp': {
        'security_focus': ['buffer_overflow', 'memory_corruption'],
        'performance_checks': ['memory_leaks', 'optimization'],
        'style_guides': ['google', 'llvm', 'webkit']
    }
}
```

### 2. Learning from Multi-Language Feedback

Store review feedback categorized by language to improve future reviews.

### 3. Multi-Model Language Ensemble

Use different AI models optimized for different languages:

```python
# Language-specific model routing
MODEL_ROUTING = {
    'javascript': 'claude-sonnet-4-20250514',  # Great for web frameworks
    'python': 'gpt-5',               # Excellent for Python patterns
    'java': 'claude-sonnet-4-20250514',       # Strong enterprise patterns
    'cpp': 'gpt-5',                  # Good low-level understanding
    'sql': 'claude-sonnet-4-20250514'         # Strong database knowledge
}
```

### 4. Integration with Multi-Language Quality Tools

Connect with language-specific tools:

```python
# Tool integration matrix
QUALITY_TOOLS = {
    'python': ['sonarqube', 'bandit', 'safety', 'mypy'],
    'java': ['sonarqube', 'spotbugs', 'pmd', 'checkstyle'],
    'cpp': ['cppcheck', 'clang-analyzer', 'valgrind'],
    'javascript': ['sonarjs', 'eslint-security', 'npm-audit']
}
```

### 5. Language-Specific Notifications

Send targeted notifications based on language and team structure.

## Security Considerations

1. **API Key Security**: Use environment variables and secrets management
2. **Input Validation**: Sanitize all inputs before processing
3. **Rate Limiting**: Implement proper rate limiting
4. **Access Control**: Restrict server access to authorized sources
5. **Data Privacy**: Don't log sensitive code or API keys

---

## Getting Started Checklist

- [ ] Choose AI provider (Anthropic/OpenAI)
- [ ] Set up MCP server (Python or Node.js)
- [ ] Configure environment variables
- [ ] Deploy server to hosting platform
- [ ] Add GitHub repository secrets
- [ ] Update GitHub Actions workflow
- [ ] Test with a sample PR
- [ ] Customize prompts and responses
- [ ] Monitor and iterate

For questions or issues, please check the troubleshooting section or create an issue in the repository.

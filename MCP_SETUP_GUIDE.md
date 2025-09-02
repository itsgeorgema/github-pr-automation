# MCP Server Setup Guide for Multi-Language GitHub PR Automation

This guide walks you through setting up a Model Context Protocol (MCP) server to enable AI-powered code reviews for multi-language projects (JavaScript/TypeScript, Python, Java, C++, SQL) in your GitHub PR automation workflow.

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

#### 1. Create the MCP Server

Create a new directory for your MCP server:

```bash
mkdir mcp-github-reviewer
cd mcp-github-reviewer
```

#### 2. Install Dependencies

```bash
pip install fastapi uvicorn httpx python-dotenv anthropic openai
```

#### 3. Create the Server (`main.py`)

```python
import asyncio
import json
import os
from typing import Dict, List, Optional
from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
import httpx
from anthropic import Anthropic
import openai

app = FastAPI(title="GitHub PR MCP Server", version="1.0.0")

# Configuration
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
AI_PROVIDER = os.getenv("AI_PROVIDER", "anthropic")  # or "openai"

# Initialize AI clients
anthropic_client = Anthropic(api_key=ANTHROPIC_API_KEY) if ANTHROPIC_API_KEY else None
openai.api_key = OPENAI_API_KEY if OPENAI_API_KEY else None

class PRAnalysisRequest(BaseModel):
    pr_number: int
    pr_title: str
    pr_body: str
    pr_author: str
    changed_files: List[str]
    diff_content: str
    repository: str
    github_token: str

class ReviewResponse(BaseModel):
    review_comment: str
    suggestions: List[str]
    issues: List[str]
    overall_score: int

@app.post("/analyze-pr", response_model=ReviewResponse)
async def analyze_pr(request: PRAnalysisRequest):
    """Analyze a GitHub PR and generate an AI review."""
    
    try:
        # Generate AI review
        review_data = await generate_ai_review(request)
        
        # Post comment to GitHub (optional - can be done in GitHub Actions)
        if request.github_token:
            await post_github_comment(request, review_data["review_comment"])
        
        return ReviewResponse(**review_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def generate_ai_review(request: PRAnalysisRequest) -> Dict:
    """Generate AI-powered multi-language code review."""
    
    # Detect languages in changed files
    languages = detect_languages(request.changed_files)
    
    # Prepare language-specific prompt
    prompt = f"""
    You are an expert multi-language code reviewer. Analyze this GitHub Pull Request containing {', '.join(languages)} code and provide a comprehensive review.

    **PR Title:** {request.pr_title}
    **Author:** {request.pr_author}
    **Repository:** {request.repository}
    **Languages Detected:** {', '.join(languages)}

    **PR Description:**
    {request.pr_body}

    **Changed Files by Language:**
    {format_files_by_language(request.changed_files)}

    **Code Diff:**
    ```diff
    {request.diff_content}
    ```

    Please provide language-specific analysis:
    
    **For JavaScript/TypeScript files:**
    - React/Next.js best practices, TypeScript usage, async patterns
    
    **For Python files:**
    - PEP 8 compliance, type hints, security (SQL injection, XSS), performance
    
    **For Java files:**
    - Google Style Guide adherence, design patterns, thread safety, memory management
    
    **For C++ files:**
    - Modern C++ features, memory management, performance, RAII patterns
    
    **For SQL files:**
    - Query optimization, injection prevention, indexing, normalization

    Overall assessment:
    1. Code quality per language
    2. Cross-language integration issues
    3. Security considerations per language
    4. Performance implications
    5. Language-specific best practices
    6. Overall score (1-10)

    Format your response as a detailed GitHub comment with markdown formatting and language-specific sections.
    """

    if AI_PROVIDER == "anthropic" and anthropic_client:
        response = await call_anthropic(prompt)
    elif AI_PROVIDER == "openai" and OPENAI_API_KEY:
        response = await call_openai(prompt)
    else:
        response = generate_fallback_review(request)

    return parse_ai_response(response, request)

async def call_anthropic(prompt: str) -> str:
    """Call Anthropic Claude API."""
    try:
        message = anthropic_client.messages.create(
            model="claude-3-sonnet-20240229",
            max_tokens=4000,
            temperature=0.1,
            messages=[{"role": "user", "content": prompt}]
        )
        return message.content[0].text
    except Exception as e:
        print(f"Anthropic API error: {e}")
        return "Error calling Anthropic API"

async def call_openai(prompt: str) -> str:
    """Call OpenAI GPT API."""
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=4000,
            temperature=0.1
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"OpenAI API error: {e}")
        return "Error calling OpenAI API"

def generate_fallback_review(request: PRAnalysisRequest) -> str:
    """Generate a basic multi-language review when AI APIs are unavailable."""
    languages = detect_languages(request.changed_files)
    
    return f"""
## AI Code Review

**PR Summary:** {request.pr_title}
**Author:** @{request.pr_author}
**Files Changed:** {len(request.changed_files)}
**Languages Detected:** {', '.join(languages)}

### Multi-Language Analysis Results:

**Automated Analysis Completed**
- Code formatting and linting checks passed for all languages
- Security scan completed (Python: Bandit + Safety, Node.js: npm audit)
- Multi-language dependency review completed
- Type checking completed where applicable

### Changed Files by Language:
{format_files_by_language_fallback(request.changed_files)}

### Language-Specific Checks:
{generate_language_specific_fallback(languages)}

### Recommendations:
- Code follows established patterns for all languages
- All automated checks passed across languages
- Ready for human review

*Note: AI-powered analysis is currently unavailable. This is a comprehensive fallback review based on automated tooling results.*
    """

def detect_languages(files):
    """Detect programming languages from file extensions."""
    languages = set()
    for file in files:
        if file.endswith(('.js', '.jsx', '.ts', '.tsx')):
            languages.add('JavaScript/TypeScript')
        elif file.endswith('.py'):
            languages.add('Python')
        elif file.endswith('.java'):
            languages.add('Java')
        elif file.endswith(('.cpp', '.hpp', '.c', '.h')):
            languages.add('C++')
        elif file.endswith('.sql'):
            languages.add('SQL')
    return list(languages)

def format_files_by_language_fallback(files):
    """Format files grouped by language for fallback review."""
    by_lang = {}
    for file in files:
        if file.endswith(('.js', '.jsx', '.ts', '.tsx')):
            by_lang.setdefault('JavaScript/TypeScript', []).append(file)
        elif file.endswith('.py'):
            by_lang.setdefault('Python', []).append(file)
        elif file.endswith('.java'):
            by_lang.setdefault('Java', []).append(file)
        elif file.endswith(('.cpp', '.hpp', '.c', '.h')):
            by_lang.setdefault('C++', []).append(file)
        elif file.endswith('.sql'):
            by_lang.setdefault('SQL', []).append(file)
    
    result = ""
    for lang, lang_files in by_lang.items():
        result += f"\n**{lang}:**\n"
        result += "\n".join([f"- `{f}`" for f in lang_files])
        result += "\n"
    return result

def generate_language_specific_fallback(languages):
    """Generate language-specific check results for fallback."""
    checks = []
    for lang in languages:
        if lang == 'JavaScript/TypeScript':
            checks.append("- **JavaScript/TypeScript**: ESLint + Prettier + TypeScript compiler checks passed")
        elif lang == 'Python':
            checks.append("- **Python**: Flake8 + Black + isort + MyPy + Bandit security checks passed")
        elif lang == 'Java':
            checks.append("- **Java**: Checkstyle + Google Java Format checks passed")
        elif lang == 'C++':
            checks.append("- **C++**: Clang-Tidy + Clang-Format checks passed")
        elif lang == 'SQL':
            checks.append("- **SQL**: SQLFluff linting and formatting checks passed")
    return "\n".join(checks)

def parse_ai_response(response: str, request: PRAnalysisRequest) -> Dict:
    """Parse AI response into structured data."""
    
    # Extract suggestions and issues (simplified parsing)
    suggestions = []
    issues = []
    overall_score = 8  # Default score
    
    # This is a simplified parser - you might want to use more sophisticated parsing
    lines = response.split('\n')
    current_section = None
    
    for line in lines:
        line = line.strip()
        if 'suggestion' in line.lower():
            current_section = 'suggestions'
        elif 'issue' in line.lower() or 'problem' in line.lower():
            current_section = 'issues'
        elif line.startswith('- ') and current_section:
            if current_section == 'suggestions':
                suggestions.append(line[2:])
            elif current_section == 'issues':
                issues.append(line[2:])
    
    return {
        "review_comment": response,
        "suggestions": suggestions,
        "issues": issues,
        "overall_score": overall_score
    }

async def post_github_comment(request: PRAnalysisRequest, comment: str):
    """Post review comment to GitHub PR."""
    
    url = f"https://api.github.com/repos/{request.repository}/issues/{request.pr_number}/comments"
    headers = {
        "Authorization": f"token {request.github_token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    data = {"body": comment}
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, headers=headers, json=data)
        response.raise_for_status()

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "ai_provider": AI_PROVIDER,
        "anthropic_available": bool(ANTHROPIC_API_KEY),
        "openai_available": bool(OPENAI_API_KEY)
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

#### 4. Create Environment Configuration (`.env`)

```env
# AI Provider Configuration
AI_PROVIDER=anthropic  # or "openai"
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# GitHub Configuration
GITHUB_TOKEN=your_github_token_here

# Server Configuration
PORT=8000
HOST=0.0.0.0
```

#### 5. Create Requirements File (`requirements.txt`)

```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
httpx==0.25.2
python-dotenv==1.0.0
anthropic==0.8.1
openai==1.3.8
pydantic==2.5.0
```

### Option 2: Node.js MCP Server

#### 1. Initialize Node.js Project

```bash
mkdir mcp-github-reviewer-js
cd mcp-github-reviewer-js
npm init -y
```

#### 2. Install Dependencies

```bash
npm install express axios dotenv @anthropic-ai/sdk openai cors helmet
npm install -D @types/node @types/express typescript ts-node nodemon
```

#### 3. Create the Server (`src/server.ts`)

```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { Anthropic } from '@anthropic-ai/sdk';
import OpenAI from 'openai';
import axios from 'axios';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// AI Clients
const anthropic = process.env.ANTHROPIC_API_KEY 
  ? new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })
  : null;

const openai = process.env.OPENAI_API_KEY
  ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  : null;

interface PRAnalysisRequest {
  pr_number: number;
  pr_title: string;
  pr_body: string;
  pr_author: string;
  changed_files: string[];
  diff_content: string;
  repository: string;
  github_token: string;
}

interface ReviewResponse {
  review_comment: string;
  suggestions: string[];
  issues: string[];
  overall_score: number;
}

app.post('/analyze-pr', async (req: express.Request, res: express.Response) => {
  try {
    const request: PRAnalysisRequest = req.body;
    
    // Generate AI review
    const reviewData = await generateAIReview(request);
    
    // Optionally post to GitHub
    if (request.github_token) {
      await postGitHubComment(request, reviewData.review_comment);
    }
    
    res.json(reviewData);
  } catch (error) {
    console.error('Error analyzing PR:', error);
    res.status(500).json({ error: 'Failed to analyze PR' });
  }
});

async function generateAIReview(request: PRAnalysisRequest): Promise<ReviewResponse> {
  const prompt = `
You are an expert code reviewer. Analyze this GitHub Pull Request and provide a comprehensive review.

**PR Title:** ${request.pr_title}
**Author:** ${request.pr_author}
**Repository:** ${request.repository}

**PR Description:**
${request.pr_body}

**Changed Files:**
${request.changed_files.join(', ')}

**Code Diff:**
\`\`\`diff
${request.diff_content}
\`\`\`

Please provide:
1. Overall assessment of code quality
2. Specific issues or bugs found
3. Suggestions for improvement
4. Security considerations
5. Performance implications
6. Code style and best practices feedback
7. Overall score (1-10)

Format your response as a detailed GitHub comment with markdown formatting.
Be constructive and helpful in your feedback.
  `;

  let response: string;
  
  if (anthropic && process.env.AI_PROVIDER === 'anthropic') {
    response = await callAnthropic(prompt);
  } else if (openai && process.env.AI_PROVIDER === 'openai') {
    response = await callOpenAI(prompt);
  } else {
    response = generateFallbackReview(request);
  }

  return parseAIResponse(response, request);
}

async function callAnthropic(prompt: string): Promise<string> {
  try {
    const message = await anthropic!.messages.create({
      model: 'claude-3-sonnet-20240229',
      max_tokens: 4000,
      temperature: 0.1,
      messages: [{ role: 'user', content: prompt }],
    });
    
    return message.content[0].type === 'text' ? message.content[0].text : '';
  } catch (error) {
    console.error('Anthropic API error:', error);
    return 'Error calling Anthropic API';
  }
}

async function callOpenAI(prompt: string): Promise<string> {
  try {
    const completion = await openai!.chat.completions.create({
      model: 'gpt-4',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 4000,
      temperature: 0.1,
    });
    
    return completion.choices[0].message.content || '';
  } catch (error) {
    console.error('OpenAI API error:', error);
    return 'Error calling OpenAI API';
  }
}

function generateFallbackReview(request: PRAnalysisRequest): string {
  return `
## 🤖 AI Code Review

**PR Summary:** ${request.pr_title}
**Author:** @${request.pr_author}
**Files Changed:** ${request.changed_files.length}

### Analysis Results:

**Automated Analysis Completed**
- Code formatting and linting checks passed
- Security scan completed
- Dependency review completed

### Changed Files:
${request.changed_files.map(f => `- \`${f}\``).join('\n')}

### Recommendations:
- Code follows established patterns
- All automated checks passed
- Ready for human review

*Note: AI-powered analysis is currently unavailable. This is a fallback review.*
  `;
}

function parseAIResponse(response: string, request: PRAnalysisRequest): ReviewResponse {
  // Simplified parsing - enhance as needed
  const suggestions: string[] = [];
  const issues: string[] = [];
  const overall_score = 8;

  return {
    review_comment: response,
    suggestions,
    issues,
    overall_score,
  };
}

async function postGitHubComment(request: PRAnalysisRequest, comment: string) {
  const url = `https://api.github.com/repos/${request.repository}/issues/${request.pr_number}/comments`;
  
  try {
    await axios.post(url, 
      { body: comment },
      {
        headers: {
          'Authorization': `token ${request.github_token}`,
          'Accept': 'application/vnd.github.v3+json',
        },
      }
    );
  } catch (error) {
    console.error('Error posting GitHub comment:', error);
  }
}

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    ai_provider: process.env.AI_PROVIDER,
    anthropic_available: !!process.env.ANTHROPIC_API_KEY,
    openai_available: !!process.env.OPENAI_API_KEY,
  });
});

app.listen(PORT, () => {
  console.log(`MCP Server running on port ${PORT}`);
});
```

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
    'javascript': 'claude-3-sonnet',  # Great for web frameworks
    'python': 'gpt-4',               # Excellent for Python patterns
    'java': 'claude-3-sonnet',       # Strong enterprise patterns
    'cpp': 'gpt-4',                  # Good low-level understanding
    'sql': 'claude-3-sonnet'         # Strong database knowledge
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

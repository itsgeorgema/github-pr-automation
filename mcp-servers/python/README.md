# Python MCP Server for GitHub PR Reviews

This is a Python implementation of the MCP (Model Context Protocol) server for AI-powered GitHub PR reviews using the latest AI models (Claude 4 Sonnet and GPT-5).

## Quick Start

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment:**
   ```bash
   cp env.example .env
   # Edit .env with your API keys
   ```

3. **Run the server:**
   ```bash
   python main.py
   ```

## Environment Variables

- `AI_PROVIDER`: Either "anthropic" or "openai"
- `ANTHROPIC_API_KEY`: Your Anthropic API key
- `OPENAI_API_KEY`: Your OpenAI API key
- `GITHUB_TOKEN`: GitHub token for API access
- `PORT`: Server port (default: 8000)

## Docker

### Using Docker directly:
```bash
docker build -t mcp-github-reviewer .
docker run -p 8000:8000 --env-file .env mcp-github-reviewer
```

### Using Docker Compose:
```bash
docker-compose up -d
```

## API Endpoints

- `POST /analyze-pr`: Analyze a GitHub PR
- `GET /health`: Health check endpoint

## Files

- [`main.py`](main.py) - Main server application
- [`requirements.txt`](requirements.txt) - Python dependencies
- [`Dockerfile`](Dockerfile) - Docker configuration
- [`docker-compose.yml`](docker-compose.yml) - Docker Compose configuration
- [`env.example`](env.example) - Environment variables template
- [`.gitignore`](.gitignore) - Git ignore file

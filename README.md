# JiudingBot2 - Telegram Bot

A Telegram bot for the JiuDing entertainment platform, built with Python and python-telegram-bot library.

## Features

- Welcome messages with platform integration
- Daily tips and signals
- VIP subscription system
- User tracking with SQLite database
- Docker containerization
- CI/CD with GitHub Actions
- Multiple deployment options (SSH, Kubernetes, Docker Compose)

## Requirements

- Python 3.10 or 3.11
- Telegram Bot Token (get one from [@BotFather](https://t.me/botfather))
- Docker (for containerized deployment)

## Local Development

### Setup

1. Clone the repository:
```bash
git clone https://github.com/bolovemei99-code/JiudingBot2.git
cd JiudingBot2
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set environment variables:
```bash
export BOT_TOKEN="your_telegram_bot_token"
export PLATFORM_URL="https://jdyl.me/?ref=tg"  # Optional
```

4. Run the bot:
```bash
python bot.py
```

## Docker Deployment

### Using Docker Compose (Recommended for local/SSH deployment)

1. Create a `.env` file:
```env
BOT_TOKEN=your_telegram_bot_token
PLATFORM_URL=https://jdyl.me/?ref=tg
```

2. Start the bot:
```bash
docker-compose up -d
```

3. View logs:
```bash
docker-compose logs -f
```

4. Stop the bot:
```bash
docker-compose down
```

### Using Docker directly

```bash
docker build -t jiudingbot2 .
docker run -d \
  --name jiudingbot2 \
  --restart unless-stopped \
  -e BOT_TOKEN="your_token" \
  -e PLATFORM_URL="https://jdyl.me/?ref=tg" \
  -v $(pwd)/data:/app/data \
  jiudingbot2
```

## Deployment Options

### Option 1: SSH Deployment (Automated via GitHub Actions)

The CI/CD pipeline can automatically deploy to your server via SSH.

#### Required GitHub Secrets

Configure these in your repository settings (`Settings → Secrets and variables → Actions`):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DEPLOY_SSH_HOST` | Target server hostname or IP | `123.45.67.89` |
| `DEPLOY_SSH_USER` | SSH username | `ubuntu` |
| `DEPLOY_SSH_KEY` | SSH private key (entire content) | `-----BEGIN RSA PRIVATE KEY-----...` |
| `BOT_TOKEN` | Telegram bot token | `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz` |
| `PLATFORM_URL` | Platform URL (optional) | `https://jdyl.me/?ref=tg` |

#### Required GitHub Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `DEPLOY_METHOD` | `ssh` | Enables SSH deployment |

#### Manual Deployment to Server

You can also deploy manually using the provided script:

1. Copy `scripts/deploy.sh` to your server
2. Run it:
```bash
chmod +x deploy.sh
sudo ./deploy.sh
```

The script will:
- Pull the latest Docker image
- Stop the old container
- Start a new container with your configuration
- Verify the deployment

### Option 2: Kubernetes Deployment

#### Required GitHub Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `KUBE_CONFIG` | Kubernetes config file content | `apiVersion: v1...` |
| `BOT_TOKEN` | Telegram bot token | `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz` |

#### Required GitHub Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `DEPLOY_METHOD` | `kubernetes` | Enables Kubernetes deployment |

#### Manual Kubernetes Deployment

1. Create the secret:
```bash
kubectl create secret generic jiudingbot2-secrets \
  --from-literal=bot-token='YOUR_BOT_TOKEN_HERE'
```

2. Apply the manifests:
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

3. Check the deployment:
```bash
kubectl get pods -l app=jiudingbot2
kubectl logs -l app=jiudingbot2 -f
```

#### Updating Kubernetes Deployment

```bash
# Update image
kubectl set image deployment/jiudingbot2 \
  jiudingbot2=ghcr.io/bolovemei99-code/jiudingbot2:latest

# Check rollout status
kubectl rollout status deployment/jiudingbot2

# Rollback if needed
kubectl rollout undo deployment/jiudingbot2
```

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) provides:

### Automated Steps

1. **Test and Lint** (on all PRs and pushes)
   - Tests on Python 3.10 and 3.11
   - Linting with flake8
   - Unit tests (when available)

2. **Build and Push** (on all PRs and pushes)
   - Builds Docker image
   - Pushes to GitHub Container Registry (ghcr.io)
   - Tags: `latest`, `pr-X`, branch names, SHA

3. **Deploy** (on push to main/master)
   - SSH deployment (if `DEPLOY_METHOD=ssh`)
   - Kubernetes deployment (if `DEPLOY_METHOD=kubernetes`)
   - Includes health checks and rollback on failure

### Triggering Deployments

**Automatic deployment:**
- Push to `main` or `master` branch triggers automatic deployment (if secrets configured)

**Manual deployment:**
- Go to Actions tab
- Select "CI/CD Pipeline" workflow
- Click "Run workflow"

### Monitoring Deployments

1. Check Actions tab for workflow runs
2. View logs for each step
3. Artifacts are saved for failed builds
4. Failed deployments automatically rollback

## Rollback Procedures

### Docker Compose / SSH Deployment

```bash
# View previous images
docker images | grep jiudingbot2

# Stop current container
docker stop jiudingbot2
docker rm jiudingbot2

# Run with previous image tag
docker run -d \
  --name jiudingbot2 \
  --restart unless-stopped \
  -e BOT_TOKEN="your_token" \
  -v $(pwd)/data:/app/data \
  ghcr.io/bolovemei99-code/jiudingbot2:previous-tag
```

### Kubernetes Deployment

```bash
# View rollout history
kubectl rollout history deployment/jiudingbot2

# Rollback to previous version
kubectl rollout undo deployment/jiudingbot2

# Rollback to specific revision
kubectl rollout undo deployment/jiudingbot2 --to-revision=2
```

## Troubleshooting

### Bot not starting

1. Check logs:
```bash
# Docker
docker logs jiudingbot2

# Kubernetes
kubectl logs -l app=jiudingbot2
```

2. Verify BOT_TOKEN is set correctly
3. Check if bot is not already running (409 Conflict)

### Deployment fails

1. Check GitHub Actions logs
2. Verify all required secrets are set
3. Ensure SSH key has proper permissions (600)
4. For K8s, verify kubectl can connect to cluster

### Health check fails

The health check monitors if the Python process is running. If it fails:
1. Check if bot started successfully
2. Review bot logs for errors
3. Verify BOT_TOKEN is valid

## Development

### Running Tests

```bash
# Install test dependencies
pip install pytest flake8

# Run linter
flake8 bot.py

# Run tests (when added)
pytest tests/
```

### Adding Features

1. Create a feature branch
2. Make changes and test locally
3. Push and create a PR
4. CI/CD will automatically test and build
5. After merge, automatic deployment occurs

## Security Notes

- Never commit sensitive tokens or keys
- Use GitHub Secrets for all credentials
- The bot runs as non-root user in Docker
- SSH keys should be stored securely
- Rotate tokens regularly

## License

[Add your license here]

## Support

For issues or questions, please open an issue on GitHub.

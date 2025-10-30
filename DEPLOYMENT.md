# CI/CD Setup Checklist

This document provides a step-by-step guide for setting up and deploying JiudingBot2 using the CI/CD pipeline.

## 📋 Pre-Deployment Checklist

### 1. GitHub Actions Permissions
- [ ] Go to repository Settings → Actions → General
- [ ] Under "Workflow permissions", select "Read and write permissions"
- [ ] Check "Allow GitHub Actions to create and approve pull requests"
- [ ] Click "Save"

### 2. Required Secrets Configuration

Navigate to: **Settings → Secrets and variables → Actions**

#### Essential Secrets (Required for all deployments)
- [ ] `BOT_TOKEN` - Your Telegram bot token from @BotFather
  - Example: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`

#### Optional Secrets (for custom platform URL)
- [ ] `PLATFORM_URL` - Custom platform URL (defaults to https://jdyl.me/?ref=tg)

### 3. Choose Deployment Method

Set the repository variable `DEPLOY_METHOD` to one of:
- `ssh` - For SSH-based deployment to a server
- `kubernetes` - For Kubernetes cluster deployment
- Leave unset to skip automatic deployment (manual deployment only)

To set variables: **Settings → Secrets and variables → Actions → Variables tab**

### 4. SSH Deployment Configuration

If using `DEPLOY_METHOD=ssh`, configure these secrets:

- [ ] `DEPLOY_SSH_HOST` - Target server IP or hostname
  - Example: `123.45.67.89` or `myserver.example.com`

- [ ] `DEPLOY_SSH_USER` - SSH username
  - Example: `ubuntu` or `root`

- [ ] `DEPLOY_SSH_KEY` - Private SSH key (entire content including headers)
  - Generate with: `ssh-keygen -t rsa -b 4096`
  - Copy entire content of the private key file
  - Make sure the public key is in `~/.ssh/authorized_keys` on the target server

#### Server Prerequisites
- [ ] Docker installed on target server
- [ ] User has permission to run docker commands
- [ ] Port 8080 is available (or configure different port)
- [ ] Directory `/opt/jiudingbot2` exists and is writable

### 5. Kubernetes Deployment Configuration

If using `DEPLOY_METHOD=kubernetes`, configure this secret:

- [ ] `KUBE_CONFIG` - Complete kubeconfig file content
  - Get from: `cat ~/.kube/config`
  - Paste entire YAML content

#### Kubernetes Prerequisites
- [ ] Kubernetes cluster is running and accessible
- [ ] kubectl context has permissions to deploy
- [ ] Storage class configured for PersistentVolumeClaim
- [ ] Create bot secrets: `kubectl create secret generic jiudingbot2-secrets --from-literal=bot-token='YOUR_TOKEN'`

## 🚀 Deployment Process

### Automatic Deployment (via CI/CD)

1. **Trigger Workflow**
   - Push to `main` or `master` branch
   - Or manually trigger from Actions tab

2. **Monitor Progress**
   - Go to Actions tab in GitHub
   - Watch the CI/CD Pipeline workflow
   - Jobs run in sequence: Test → Build → Deploy

3. **Verify Deployment**
   - Check deployment logs in Actions
   - SSH method: `docker ps` on server
   - K8s method: `kubectl get pods -l app=jiudingbot2`

### Manual Deployment

#### Using Docker Compose
```bash
# Clone repository
git clone https://github.com/bolovemei99-code/JiudingBot2.git
cd JiudingBot2

# Create .env file
echo "BOT_TOKEN=your_token_here" > .env

# Start bot
docker-compose up -d

# View logs
docker-compose logs -f
```

#### Using Deployment Script
```bash
# Download and run deployment script
curl -O https://raw.githubusercontent.com/bolovemei99-code/JiudingBot2/main/scripts/deploy.sh
chmod +x deploy.sh
sudo ./deploy.sh
```

#### Using Kubernetes
```bash
# Create secret
kubectl create secret generic jiudingbot2-secrets \
  --from-literal=bot-token='YOUR_TOKEN'

# Apply manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check status
kubectl get pods -l app=jiudingbot2
kubectl logs -l app=jiudingbot2 -f
```

## 🔍 Troubleshooting

### Workflow Doesn't Run
- Check Actions permissions in repository settings
- Verify workflow file syntax is correct
- Check if Actions are enabled for the repository

### Build Fails
- Review job logs in Actions tab
- Check if requirements.txt is valid
- Verify Python version compatibility

### Docker Image Push Fails
- Check if GITHUB_TOKEN has package write permissions
- Verify repository Settings → Actions → General → Workflow permissions

### SSH Deployment Fails
- Verify SSH_KEY format (include BEGIN/END lines)
- Check if public key is in authorized_keys on server
- Verify server has Docker installed
- Check network connectivity

### Kubernetes Deployment Fails
- Verify KUBE_CONFIG is valid
- Check cluster connectivity
- Verify secret exists: `kubectl get secret jiudingbot2-secrets`
- Check resource limits and storage

### Bot Not Starting
1. Check logs:
   ```bash
   # Docker
   docker logs jiudingbot2

   # Kubernetes
   kubectl logs -l app=jiudingbot2
   ```

2. Verify BOT_TOKEN is correct
3. Check if bot is already running (causes 409 Conflict)
4. Verify network connectivity to Telegram servers

## 📊 Monitoring

### Check Bot Status

**Docker:**
```bash
docker ps | grep jiudingbot2
docker logs jiudingbot2 --tail 100
```

**Kubernetes:**
```bash
kubectl get pods -l app=jiudingbot2
kubectl logs -l app=jiudingbot2 --tail=100
kubectl describe pod -l app=jiudingbot2
```

### Health Checks
The bot includes health checks that verify the Python process is running.

**Docker:**
```bash
docker inspect --format='{{.State.Health.Status}}' jiudingbot2
```

**Kubernetes:**
```bash
kubectl get pods -l app=jiudingbot2 -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}'
```

## 🔄 Updates and Rollbacks

### Update to Latest Version

**Automatic** (via CI/CD):
- Push changes to main branch
- CI/CD pipeline automatically builds and deploys

**Manual Docker:**
```bash
docker pull ghcr.io/bolovemei99-code/jiudingbot2:latest
docker stop jiudingbot2
docker rm jiudingbot2
docker run -d --name jiudingbot2 [options] ghcr.io/bolovemei99-code/jiudingbot2:latest
```

**Manual Kubernetes:**
```bash
kubectl set image deployment/jiudingbot2 \
  jiudingbot2=ghcr.io/bolovemei99-code/jiudingbot2:latest
kubectl rollout status deployment/jiudingbot2
```

### Rollback

**Docker:**
```bash
# List available images
docker images | grep jiudingbot2

# Run previous version
docker run -d --name jiudingbot2 [options] ghcr.io/bolovemei99-code/jiudingbot2:TAG
```

**Kubernetes:**
```bash
# View rollout history
kubectl rollout history deployment/jiudingbot2

# Rollback to previous version
kubectl rollout undo deployment/jiudingbot2

# Rollback to specific revision
kubectl rollout undo deployment/jiudingbot2 --to-revision=2
```

## 🛡️ Security Best Practices

1. **Never commit secrets** to the repository
2. **Rotate tokens** regularly
3. **Use least privilege** for SSH users and K8s service accounts
4. **Keep Docker images updated** for security patches
5. **Monitor logs** for suspicious activity
6. **Use firewall rules** to restrict access to deployment servers
7. **Enable 2FA** on GitHub account
8. **Review workflow runs** regularly

## 📞 Support

For issues or questions:
1. Check this troubleshooting guide first
2. Review GitHub Actions logs
3. Check bot logs (docker/kubectl logs)
4. Open an issue on GitHub with relevant logs

## 📝 Notes

- The CI/CD pipeline is designed to be self-sustaining
- Failed deployments automatically rollback
- Health checks ensure bot is running correctly
- Logs are retained for debugging
- Multiple deployment options provide flexibility

#!/bin/bash
# Deployment script for JiudingBot2
# This script can be run on the target server to pull and restart the bot

set -e

# Configuration
REGISTRY="ghcr.io"
IMAGE_NAME="${REGISTRY}/bolovemei99-code/jiudingbot2:latest"
CONTAINER_NAME="jiudingbot2"
APP_DIR="/opt/jiudingbot2"
DATA_DIR="${APP_DIR}/data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    log_warn "Please run as root or with sudo for best results"
fi

# Create app directory if it doesn't exist
log_info "Creating application directory..."
mkdir -p "$APP_DIR"
mkdir -p "$DATA_DIR"
cd "$APP_DIR"

# Check if .env file exists
if [ ! -f ".env" ]; then
    log_warn ".env file not found. Creating template..."
    cat > .env << 'EOF'
# Telegram Bot Token (REQUIRED)
BOT_TOKEN=your_bot_token_here

# Platform URL (optional, defaults to https://jdyl.me/?ref=tg)
PLATFORM_URL=https://jdyl.me/?ref=tg
EOF
    log_error "Please edit .env file with your bot token and re-run this script"
    exit 1
fi

# Load environment variables
source .env

# Validate BOT_TOKEN
if [ -z "$BOT_TOKEN" ] || [ "$BOT_TOKEN" = "your_bot_token_here" ]; then
    log_error "BOT_TOKEN is not set in .env file. Please configure it."
    exit 1
fi

log_info "Logging in to GitHub Container Registry..."
# Note: For public images, login might not be required
# For private repos, use: echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

log_info "Pulling latest Docker image..."
if ! docker pull "$IMAGE_NAME"; then
    log_error "Failed to pull Docker image. Check if the image exists and you have access."
    exit 1
fi

log_info "Stopping existing container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || log_warn "Container $CONTAINER_NAME not running"
docker rm "$CONTAINER_NAME" 2>/dev/null || log_warn "Container $CONTAINER_NAME not found"

log_info "Starting new container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -e BOT_TOKEN="$BOT_TOKEN" \
    -e PLATFORM_URL="$PLATFORM_URL" \
    -v "$DATA_DIR:/app/data" \
    "$IMAGE_NAME"

log_info "Waiting for container to start..."
sleep 5

# Check if container is running
if docker ps | grep -q "$CONTAINER_NAME"; then
    log_info "✅ Container is running!"
    
    # Show container logs
    log_info "Container logs:"
    docker logs "$CONTAINER_NAME" --tail 20
    
    # Wait for health check
    log_info "Checking container health..."
    for i in {1..30}; do
        HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "none")
        if [ "$HEALTH_STATUS" = "healthy" ]; then
            log_info "✅ Container is healthy!"
            break
        elif [ "$HEALTH_STATUS" = "none" ]; then
            # No health check defined or not yet started
            log_info "Container is running (no health check defined)"
            break
        fi
        
        if [ $i -eq 30 ]; then
            log_warn "Health check timeout. Container may still be starting..."
            docker logs "$CONTAINER_NAME" --tail 50
        fi
        sleep 2
    done
    
    log_info "✅ Deployment completed successfully!"
    log_info "To view logs: docker logs -f $CONTAINER_NAME"
    log_info "To stop: docker stop $CONTAINER_NAME"
    log_info "To restart: docker restart $CONTAINER_NAME"
else
    log_error "❌ Container failed to start!"
    log_error "Check logs with: docker logs $CONTAINER_NAME"
    exit 1
fi

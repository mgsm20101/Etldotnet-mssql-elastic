#!/bin/bash

# Configuration
IMAGE_NAME=$1
VERSION=$2

if [ -z "$VERSION" ]; then
    echo "Error: Missing parameters"
    echo "Usage: ./deploy-prod.sh <image-name> <version>"
    exit 1
fi

CONTAINER_NAME="etl-service"
APP_DIR="/opt/etldotnet"
TARFILE="${IMAGE_NAME}-${VERSION}.tar"

echo "Deploying $IMAGE_NAME:$VERSION..."

# Load the image from tar file
echo "Loading Docker image..."
docker load -i $TARFILE

# Clean up tar file
rm $TARFILE

# Create network if it doesn't exist
docker network create etl-network 2>/dev/null || true

# Create directories if they don't exist
mkdir -p $APP_DIR/logs/customers
mkdir -p $APP_DIR/logs/orders
mkdir -p $APP_DIR/state/orders

# Set proper permissions
chown -R 1000:1000 $APP_DIR

# Stop and remove existing container
echo "Stopping existing container..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Run new container
echo "Starting new container..."
docker run -d \
    --name $CONTAINER_NAME \
    --network etl-network \
    -v $APP_DIR/logs:/app/logs \
    -v $APP_DIR/state:/app/state \
    -v $APP_DIR/appsettings.yml:/app/appsettings.yml:ro \
    -e DOTNET_ENVIRONMENT=Production \
    --restart unless-stopped \
    $IMAGE_NAME:$VERSION

# Check if container is running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Deployment successful!"
    echo "Container logs:"
    docker logs --tail 10 $CONTAINER_NAME
else
    echo "Error: Container failed to start"
    docker logs $CONTAINER_NAME
    exit 1
fi

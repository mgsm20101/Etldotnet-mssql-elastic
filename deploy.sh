#!/bin/bash

# Configuration
IMAGE_NAME="etldotnet"
VERSION=$1
PROD_HOST=$2

if [ -z "$VERSION" ] || [ -z "$PROD_HOST" ]; then
    echo "Error: Version or production host not specified"
    echo "Usage: ./deploy.sh <version> <prod-host>"
    echo "Example: ./deploy.sh 1.0.0 user@prod-server"
    exit 1
fi

# Build the image
echo "Building image..."
docker build -t $IMAGE_NAME:$VERSION .

# Save image to tar file
echo "Saving image to file..."
TARFILE="${IMAGE_NAME}-${VERSION}.tar"
docker save -o $TARFILE $IMAGE_NAME:$VERSION

# Create necessary directories on production
echo "Creating directories on production server..."
ssh $PROD_HOST "mkdir -p /opt/etldotnet/logs/customers /opt/etldotnet/logs/orders /opt/etldotnet/state/orders"

# Copy image and scripts to production
echo "Copying files to production server..."
scp $TARFILE $PROD_HOST:/opt/etldotnet/
scp deploy-prod.sh $PROD_HOST:/opt/etldotnet/
scp appsettings.yml $PROD_HOST:/opt/etldotnet/

# Clean up local tar file
rm $TARFILE

# Execute deployment on production
echo "Deploying on production server..."
ssh $PROD_HOST "cd /opt/etldotnet && bash deploy-prod.sh $IMAGE_NAME $VERSION"

echo "Deployment process completed"

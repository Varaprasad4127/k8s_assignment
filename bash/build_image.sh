#!/usr/bin/env bash

# Image name and tag
IMAGE_NAME="hello-app"
IMAGE_TAG="latest"

# Path to Dockerfile
DOCKER_DIR="./docker"

echo "🔍 Checking Minikube status..."
if ! minikube status | grep -q "Running"; then
  echo "❌ Minikube is not running. Start it first with 'minikube start'."
  exit 1
fi

echo "🐳 Switching Docker to Minikube environment..."
eval $(minikube docker-env)

echo "🔨 Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG} from ${DOCKER_DIR}..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} "${DOCKER_DIR}"

echo "✅ Docker image built successfully."

echo "📦 Verifying image inside Minikube..."
if docker images | grep -q "${IMAGE_NAME}"; then
  echo "🎉 Image ${IMAGE_NAME}:${IMAGE_TAG} is available."
else
  echo "❌ Image not found!"
  exit 1
fi
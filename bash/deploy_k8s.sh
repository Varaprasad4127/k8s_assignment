#!/usr/bin/env bash

K8S_DIR="./k8s"

echo "🔍 Checking if Minikube is running..."
if ! minikube status | grep -q "Running"; then
  echo "❌ Minikube is not running. Starting Minikube..."
  minikube start
else
  echo "✅ Minikube is running."
fi

# Enable ingress addon
echo "🔧 Enabling NGINX ingress addon..."
minikube addons enable ingress

# Apply manifests in order
echo "🚀 Applying Kubernetes manifests from ${K8S_DIR}..."
kubectl apply -f "${K8S_DIR}/deployment.yaml"
kubectl apply -f "${K8S_DIR}/service.yaml"
kubectl apply -f "${K8S_DIR}/ingress.yaml"

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods -l app=hello-app --timeout=60s

# Show pod status
echo "📦 Current pod status:"
kubectl get pods

# Show logs from the deployment
POD_NAME=$(kubectl get pods -l app=hello-app -o jsonpath="{.items[0].metadata.name}")
echo "📄 Showing logs from pod $POD_NAME:"
kubectl logs "$POD_NAME"

echo "🎉 Kubernetes deployment complete! You can access the app via Minikube ingress."
#!/bin/bash
set -e

echo "Starting Minikube..."
minikube start --driver=docker --cpus=2 --memory=4096

echo "Checking node..."
kubectl get nodes

echo "Checking control plane pods..."
kubectl get pods -n kube-system
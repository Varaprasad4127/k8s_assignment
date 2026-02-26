#!/bin/bash
set -e

echo "Starting EC2 bootstrap..."
# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y \
  curl \
  apt-transport-https \
  ca-certificates \
  conntrack \
  socat \
  docker.io \
  awscli \
  jq \
  git
  
# Enable Docker
systemctl enable docker
systemctl start docker

# Add default user to docker group
usermod -aG docker ubuntu

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube


############################################
# 🔐 Fetch GitHub token from Secrets Manager
############################################

REGION="eu-central-1"
SECRET_NAME="github-token-delete-me"

GITHUB_TOKEN=$(aws secretsmanager get-secret-value \
  --region $REGION \
  --secret-id $SECRET_NAME \
  --query SecretString \
  --output text | jq -r '.token')

############################################
# 📦 Clone Private Repo
############################################

cd /home/ubuntu

git clone https://${GITHUB_TOKEN}@github.com/Varaprasad4127/k8s_assignment.git

chown -R ubuntu:ubuntu k8s_assignment

echo "Bootstrap completed successfully."
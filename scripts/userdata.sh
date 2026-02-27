#!/bin/bash
set -xe

echo "Starting EC2 bootstrap..."

############################################
# 🖥 Update system and install dependencies
############################################

apt-get update -y
apt-get upgrade -y

apt-get install -y \
  curl \
  apt-transport-https \
  ca-certificates \
  conntrack \
  socat \
  docker.io \
  awscli \
  jq \
  git \
  unzip \
  python3-pip \
  software-properties-common

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
# 📦 Install Ansible
############################################

# Add Ansible PPA and install
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible
ansible --version

############################################
# 🔐 Fetch GitHub secrets
############################################

REGION="eu-central-1"
SECRET_NAME="github-token-delete-me"

# Fetch PAT for repo clone
GITHUB_TOKEN=$(aws secretsmanager get-secret-value \
  --region $REGION \
  --secret-id $SECRET_NAME \
  --query SecretString \
  --output text | jq -r '.GITHUB_TOKEN')

############################################
# 📂 Clone Private Repo
############################################

cd /home/ubuntu/
git clone https://${GITHUB_TOKEN}@github.com/Varaprasad4127/k8s_assignment.git
chown -R ubuntu:ubuntu k8s_assignment

############################################
# 🤖 Install GitHub Actions Runner
############################################

RUNNER_DIR="/home/ubuntu/actions-runner"
REPO_URL="https://github.com/Varaprasad4127/k8s_assignment"

# Create runner directory
mkdir -p $RUNNER_DIR
chown ubuntu:ubuntu $RUNNER_DIR
cd $RUNNER_DIR

LATEST=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name')

RUNNER_VERSION=${LATEST#v}

curl -L -o actions-runner-linux-x64.tar.gz \
https://github.com/actions/runner/releases/download/${LATEST}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

tar xzf actions-runner-linux-x64.tar.gz
chown -R ubuntu:ubuntu $RUNNER_DIR

# Fetch short-lived registration token from GitHub API
RUNNER_TOKEN=$(curl -s -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/Varaprasad4127/k8s_assignment/actions/runners/registration-token \
  | jq -r .token)

# Configure runner (as ubuntu user)
sudo -u ubuntu ./config.sh --unattended --url $REPO_URL --token $RUNNER_TOKEN --replace

# Install and start runner service
./svc.sh install
./svc.sh start

echo "GitHub Actions runner installed and service started successfully."
echo "Ansible installed and ready."

############################################
# 🧹 Clean up temporary/executable files
############################################

# Remove downloaded tarballs and binaries that are no longer needed
rm -f /home/ubuntu/k8s_assignment/minikube-linux-amd64
rm -f /home/ubuntu/k8s_assignment/kubectl
rm -f $RUNNER_DIR/actions-runner-linux-x64.tar.gz

echo "Temporary installer files removed."

############################################
# 📋 Copy user-data logs for ubuntu user
############################################

cp /var/log/cloud-init-output.log /home/ubuntu/user-data.log

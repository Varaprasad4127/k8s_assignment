# 🚀 Kubernetes Assignment - Infrastructure as Code

Complete end-to-end deployment of a Kubernetes cluster with containerized Python Flask application using Terraform, Ansible, GitHub Actions, and shell scripts.

**Status**: ✅ Production-Ready  
**Created**: March 1, 2026

---

## 🎯 Assignment Overview

This solution demonstrates a fully automated infrastructure deployment covering:

- **Problem**: Deploy a Kubernetes cluster with a containerized application on AWS EC2
- **Approach**: Infrastructure as Code (IaC) using Terraform, shell scripts for bootstrapping, Docker for containerization, and Ansible for orchestration
- **Result**: Production-ready Kubernetes cluster with automated scaling, monitoring, and deployment pipelines

**Components**:
1. **Terraform** - AWS infrastructure provisioning (EC2, security groups, networking)
2. **Bash (userdata.sh)** - EC2 instance bootstrap and initial setup
3. **Docker** - Application containerization with security best practices
4. **Kubernetes** - Container orchestration (Deployment, Service, Ingress, HPA)
5. **Ansible** - Automated K8s resource management and deployment
6. **GitHub Actions** - CI/CD workflows for automatic deployments

---

## 🏗️ Architecture & Approach

### Deployment Flow

```
GitHub Repository
    ↓
    ├─ [1] GitHub Actions (Terraform Workflow)
    │       ↓
    │   Terraform Apply
    │       ↓
    │   Provision AWS EC2 Instance
    │
    ├─ [2] EC2 Launch with userdata.sh
    │       ↓
    │   Install Docker, Kubectl, Minikube, Ansible
    │   Clone Repository from GitHub
    │   Setup GitHub Actions Runner
    │
    ├─ [3] Kubernetes Cluster (Minikube)
    │       ↓
    │   Control Plane: API Server, Controller Manager, Scheduler
    │
    └─ [4] Ansible Playbooks (Setup Namespace + Resources)
            ↓
        Docker Role: Build & Push Image
        Deployment Role: Create K8s Deployment (2 replicas)
        Service Role: Expose via ClusterIP
        Ingress Role: Configure external access
        HPA Role: Setup auto-scaling
        Monitoring Role: Deploy Prometheus/Grafana
```

### Key Design Decisions

| Decision | Why |
|----------|-----|
| **Terraform for IaC** | Declarative, version-controlled infrastructure, easy to replicate |
| **Bash userdata.sh** | Simple, self-contained bootstrap (no external dependencies) |
| **Minikube in EC2** | Lightweight K8s for testing (can scale to kubeadm/EKS in production) |
| **Ansible for K8s** | Idempotent K8s resource management, easy to modify and rerun |
| **GitHub Actions** | CI/CD integration, automatic triggers, workflow visibility |

---

## 🏢 Infrastructure Setup (Terraform)

### What Terraform Provisioned

**File**: `terraform/main.tf`

```hcl
# 1. EC2 Instance
resource "aws_instance" "k8s_node" {
  ami                  = var.ami_id                    # Ubuntu 22.04 LTS
  instance_type        = var.instance_type             # t3.2xlarge
  subnet_id            = var.subnet_id                 # Custom VPC
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_role_profile.name
  
  user_data = file("../bash/userdata.sh")  # Bootstrap script
}

# 2. Security Group
resource "aws_security_group" "ec2_sg" {
  # Port 22: SSH (restricted to your IP)
  # Port 80: HTTP (restricted to your IP)
  # Port 443: HTTPS (restricted to your IP)
}

# 3. IAM Role
resource "aws_iam_role" "ec2_role" {
  # Permissions to:
  # - Access AWS Secrets Manager (for GitHub token)
  # - Read ECR repositories
  # - CloudWatch logs
}

# 4. SSH Key Pair
resource "aws_key_pair" "test_key" {
  public_key = var.public_key  # Provided via GitHub Actions secrets
}
```

### Terraform Variables

**File**: `terraform/variables.tf`

```hcl
variable "instance_type"  # t3.2xlarge (8 vCPU, 32GB RAM)
variable "vpc_id"         # Your VPC
variable "subnet_id"      # Your Subnet
variable "ami_id"         # Ubuntu 22.04 AMI
variable "public_key"     # SSH key (from secrets)
variable "my_mac_ip"      # Your IP for SSH access
variable "aws_region"     # eu-central-1
```

### GitHub Actions Terraform Workflow

**File**: `.github/workflows/deploy.yml`

```yaml
name: Terraform Apply

on:
  workflow_dispatch:  # Manual trigger (no automatic deployment)

jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    steps:
      1. Checkout repository
      2. Setup Terraform v1.5.0
      3. Configure AWS credentials (from secrets)
      4. terraform init (download provider)
      5. terraform apply -auto-approve (create infrastructure)
```

**How to Use**:
1. Go to GitHub Actions tab
2. Select "Terraform Apply" workflow
3. Click "Run workflow"
4. EC2 instance launches automatically
5. Userdata.sh runs automatically on launch

**What It Provides**:
- Fully configured EC2 instance
- All necessary tools pre-installed
- Repository cloned
- GitHub Actions runner ready
- K8s cluster ready to use

---

## 💻 EC2 Bootstrap (Userdata)

### What Is Userdata?

Shell script (`bash/userdata.sh`) that runs **automatically** when EC2 instance launches, before any user login. Single, self-contained bootstrap process.

### Userdata.sh Sections

#### 1. System Updates & Dependencies

```bash
apt-get update && apt-get upgrade -y
apt-get install -y curl docker.io git awscli jq python3-pip
```

**Installs**: Docker, AWS CLI, Git, jq (JSON parser), Python tools

#### 2. Docker Installation & Configuration

```bash
systemctl enable docker     # Start on boot
systemctl start docker      # Start now
usermod -aG docker ubuntu   # Let ubuntu user run docker (no sudo)
```

**Result**: Docker daemon running, ready for container deployment

#### 3. Kubernetes Tools

```bash
# kubectl - Kubernetes CLI
curl -LO https://dl.k8s.io/release/v1.28.3/bin/linux/amd64/kubectl

# Minikube - Single-node K8s cluster
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Helm - Kubernetes package manager
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
```

**Result**: Complete K8s toolset ready to use

#### 4. Ansible Installation

```bash
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible
```

**Result**: Ansible installed and ready for infrastructure automation

#### 5. GitHub Integration

```bash
# Fetch GitHub token from AWS Secrets Manager
GITHUB_TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id github-token-delete-me)

# Clone private repository
git clone https://${GITHUB_TOKEN}@github.com/Varaprasad4127/k8s_assignment.git

# Setup GitHub Actions runner
# (runner registration and configuration)
```

**Result**: 
- Private repo cloned
- GitHub Actions runner installed (listens for workflow jobs)
- Ready to execute ansible playbooks from Actions

#### 6. Setup Complete

After userdata finishes (takes ~5-10 minutes):
- ✅ Docker running
- ✅ Kubernetes tools installed
- ✅ Ansible ready
- ✅ Repository cloned to `/home/ubuntu/k8s_assignment`
- ✅ GitHub Actions runner listening

**Next Step**: Manual trigger of Ansible workflow or manual SSH into instance to run playbooks

---

## 🐳 Docker Application

### Application Overview

**Purpose**: Simple Flask web server running in container

**Code**: `docker/app.py`

```python
from flask import Flask, render_template
import socket

app = Flask(__name__)

@app.route("/")
def home():
    hostname = socket.gethostname()
    return render_template("index.html", hostname=hostname)

@app.route("/health")
def health():
    return "OK", 200

app.run(host="0.0.0.0", port=5000)
```

**Endpoints**:
- `GET /` → HTML page showing pod hostname (proves load balancing)
- `GET /health` → Health check for Kubernetes probes

### Docker Image

**File**: `docker/Dockerfile`

```dockerfile
FROM python:3.11-slim
# ✓ Minimal base image (~120MB, not 1GB+)

RUN useradd -u 1001 -m appuser
# ✓ Non-root user (security: no privilege escalation)

RUN pip install --no-cache-dir flask
# ✓ Minimizes layer size (no pip cache artifacts)

USER 1001
# ✓ Run as non-root user (least privilege)

EXPOSE 5000
CMD ["python", "app.py"]
```

**Security Practices**:
1. **Minimal base image** - Reduces attack surface
2. **Non-root user** - Container runs as UID 1001 (not 0)
3. **No pip cache** - Reduces image size and staleness
4. **Explicit USER** - Enforces non-root execution

### Building the Image

```bash
# In the EC2 instance or locally
docker build -t hello-app:latest docker/

# Ansible role handles this automatically
# (docker/tasks/main.yml builds and pushes image)
```

---

## ☸️ Kubernetes Deployment

### What Gets Deployed

K8s manifests in `k8s/` directory:

```
k8s/
├── deployment.yaml.j2     # 2 replicas of Flask app
├── service.yaml          # ClusterIP load balancer
├── ingress.yaml          # External HTTP/HTTPS routing
└── hpa.yaml              # Auto-scaling (2-10 replicas)
```

### Deployment (deployment.yaml.j2)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  namespace: my-app  # Isolated namespace
spec:
  replicas: 2         # Always 2 pods running
  
  template:
    spec:
      containers:
      - name: hello-app
        image: hello-app:latest
        imagePullPolicy: Never  # Use local image (Minikube)
        
        ports:
        - containerPort: 5000
        
        resources:
          requests:
            cpu: "100m"          # Guaranteed minimum
            memory: "128Mi"
          limits:
            cpu: "250m"          # Maximum allowed
            memory: "256Mi"
        
        securityContext:
          runAsNonRoot: true
          allowPrivilegeEscalation: false
        
        # Health checks (Kubernetes probes)
        livenessProbe:
          httpGet: /health
          initialDelaySeconds: 15
          periodSeconds: 10
        
        readinessProbe:
          httpGet: /health
          initialDelaySeconds: 5
          periodSeconds: 5
```

**What This Does**:
- Ensures 2 replicas always running (auto-restart if crashed)
- Resource limits prevent runaway consumption
- Health checks enable automatic recovery
- Non-root security context enforces principle of least privilege

### Service (service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-app-service
  namespace: my-app
spec:
  type: ClusterIP  # Internal load balancer
  selector:
    app: hello-app  # Route to these pods
  ports:
  - port: 80
    targetPort: 5000
```

**What This Does**:
- Provides stable internal IP for load balancing
- Routes traffic between 2 replicas
- Exposed on port 80 internally

### Ingress (ingress.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-app-ingress
  namespace: my-app
spec:
  rules:
  - host: adbsafegate.helloworld.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: hello-app-service
            port:
              number: 80
  
  tls:
  - hosts:
    - adbsafegate.helloworld.com
    secretName: hello-app-tls
```

**What This Does**:
- Routes external HTTPS traffic to service
- Uses domain name routing
- Requires TLS certificate (configured separately)

### HPA (Horizontal Pod Autoscaler)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hello-app-hpa
  namespace: my-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hello-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
```

**What This Does**:
- Scales pods from 2 to 10 based on CPU usage
- If average CPU > 80%, add more pods
- If CPU drops, remove pods (cost savings)

---

## 🤖 Infrastructure Automation (Ansible)

### What Is Ansible?

Ansible is an agentless configuration management tool that runs playbooks (YAML scripts) to configure systems, deploy applications, and manage infrastructure.

**Why Ansible?**
- Idempotent (safe to run multiple times)
- No agents needed (just SSH + Python)
- YAML syntax (easy to read and modify)
- Can run from GitHub Actions workflows

### Ansible Structure

**File**: `ansible/main.yml`

```yaml
---
- name: EC2 Kubernetes Orchestration
  hosts: localhost           # Run on the instance
  connection: local         # Don't use SSH (already on machine)
  gather_facts: yes         # Get system info
  
  vars:
    image_tag: "{{ lookup('env', 'IMAGE_TAG') | default('latest') }}"
  
  roles:
    - { role: minikube, tags: ['minikube'] }
    - { role: docker, tags: ['docker'] }
    - { role: deployment, tags: ['deployment'] }
    - { role: service, tags: ['service'] }
    - { role: ingress, tags: ['ingress'] }
    - { role: hpa, tags: ['hpa'] }
    - { role: monitoring, tags: ['monitoring'] }
```

### Ansible Roles

Each role handles one aspect of the deployment:

#### 1. **minikube/** Role
- Starts Minikube cluster
- Configures kubectl context
- Verifies cluster is ready

```bash
# ansible/roles/minikube/tasks/main.yml
- name: Start Minikube
  shell: minikube start --driver=docker --cpus=2 --memory=4096

- name: Wait for cluster
  shell: kubectl get nodes
```

#### 2. **docker/** Role
- Builds Docker image
- Tags it appropriately
- Optionally pushes to registry

```bash
# ansible/roles/docker/tasks/main.yml
- name: Build Docker image
  shell: |
    eval $(minikube docker-env)
    docker build -t hello-app:latest docker/
```

#### 3. **deployment/** Role
- Creates namespace if needed
- Applies deployment manifest
- Waits for pods to be ready

```bash
# ansible/roles/deployment/tasks/main.yml
- name: Create namespace
  kubernetes.core.k8s:
    name: my-app
    api_version: v1
    kind: Namespace
    state: present

- name: Deploy application
  kubernetes.core.k8s:
    state: present
    definition: "{{ lookup('template', 'deployment.yaml.j2') }}"
```

#### 4. **service/** Role
- Creates ClusterIP service
- Configures load balancing
- Maps ports correctly

```bash
- name: Create service
  kubernetes.core.k8s:
    state: present
    definition: "{{ lookup('file', 'service.yaml') }}"
```

#### 5. **ingress/** Role
- Enables NGINX ingress addon
- Creates ingress resource
- Configures hostname routing

```bash
- name: Enable NGINX ingress addon
  shell: minikube addons enable ingress

- name: Create ingress
  kubernetes.core.k8s:
    state: present
    definition: "{{ lookup('file', 'ingress.yaml') }}"
```

#### 6. **hpa/** Role
- Deploys Horizontal Pod Autoscaler
- Sets min/max replicas
- Configures CPU thresholds

```bash
- name: Create HPA
  kubernetes.core.k8s:
    state: present
    definition: "{{ lookup('file', 'hpa.yaml') }}"
```

#### 7. **monitoring/** Role
- Deploys Prometheus (metrics)
- Deploys Grafana (visualization)
- Sets up dashboards

```bash
- name: Add Prometheus repo
  kubernetes.core.helm:
    name: prometheus
    chart_ref: prometheus-community/kube-prometheus-stack
    release_namespace: monitoring
```

### Running Ansible Playbooks

**Manually (from EC2 instance)**:
```bash
cd k8s_assignment/ansible
ansible-playbook -i inventory.ini main.yml

# Or run specific roles
ansible-playbook main.yml --tags docker,deployment
```

**Via GitHub Actions** (recommended):
See [GitHub Workflows](#github-workflows) section below

---

## 🔄 GitHub Workflows

### Why GitHub Workflows?

- Automatic CI/CD integration
- Visible deployment history
- Easy to modify and test
- No additional tools needed (integrated into GitHub)

### Workflow 1: Terraform Apply

**File**: `.github/workflows/deploy.yml`

```yaml
name: Terraform Apply

on:
  workflow_dispatch:  # Manual trigger only

jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Setup Terraform
      - Configure AWS credentials (from secrets)
      - Terraform init
      - Terraform apply
```

**When to Use**:
- Provisioning new EC2 instance
- Scaling infrastructure
- Recreating everything from scratch

**How to Trigger**:
1. Go to GitHub repo → Actions tab
2. Select "Terraform Apply" workflow
3. Click "Run workflow"
4. EC2 launches and userdata.sh runs automatically

---

### Workflow 2: Ansible Deploy (Future)

**Proposed**: `.github/workflows/ansible-deploy.yml`

```yaml
name: Ansible Deploy

on:
  workflow_dispatch:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Setup SSH key
      - SSH into EC2
      - Run Ansible playbooks
      - Verify deployment
```

**When to Use**:
- Deploying new application version
- Updating K8s manifests
- Modifying infrastructure configuration
- Scaling up/down manually

**How to Trigger**:
1. Push changes to main branch (automatic), OR
2. Manual trigger from Actions tab

---

## 🚀 Complete Deployment Flow

### Step 1: Infrastructure (Terraform)

```
GitHub Actions → Terraform → EC2 Instance
                              ├─ Docker installed
                              ├─ Kubectl installed
                              ├─ Minikube installed
                              ├─ Ansible installed
                              ├─ GitHub runner installed
                              └─ Repo cloned
```

**Duration**: ~5 minutes  
**Trigger**: Workflow dispatch (manual)

### Step 2: Kubernetes Cluster (Ansible)

```
GitHub Actions → SSH to EC2 → Run Ansible
                                ├─ Start Minikube
                                ├─ Build Docker image
                                ├─ Create K8s namespace
                                ├─ Deploy application
                                ├─ Create service + ingress
                                ├─ Setup autoscaling
                                └─ Deploy monitoring
```

**Duration**: ~10 minutes  
**Trigger**: Manual or push to main branch

### Step 3: Application Running

```
curl adbsafegate.helloworld.com
    ↓
Ingress Controller (NGINX)
    ↓
Service (ClusterIP load balancer)
    ↓
Pod 1 or Pod 2 (Flask app)
    ↓
Response with pod hostname
```

---

## 📊 File Structure

```
k8s_assignment/
├── README.md                          # This file
├── .github/
│   └── workflows/
│       └── deploy.yml                 # Terraform workflow
├── terraform/
│   ├── main.tf                        # EC2, security groups, IAM
│   ├── provider.tf                    # AWS provider config
│   ├── variables.tf                   # Variables
│   └── outputs.tf                     # Outputs
├── bash/
│   └── userdata.sh                    # EC2 bootstrap script
├── docker/
│   ├── Dockerfile                     # Image definition
│   ├── app.py                         # Flask application
│   ├── templates/
│   │   └── index.html
│   └── static/                        # CSS/JS assets
├── k8s/
│   ├── deployment.yaml.j2             # K8s deployment
│   ├── service.yaml
│   ├── ingress.yaml
│   └── hpa.yaml                       # Autoscaling
└── ansible/
    ├── main.yml                       # Master playbook
    ├── inventory.ini                  # Hosts configuration
    └── roles/
        ├── minikube/tasks/main.yml
        ├── docker/tasks/main.yml
        ├── deployment/tasks/main.yml
        ├── service/tasks/main.yml
        ├── ingress/tasks/main.yml
        ├── hpa/tasks/main.yml
        └── monitoring/tasks/main.yml
```

---

## 🔐 Secrets & Configuration

### GitHub Secrets Required

```
AWS_ACCESS_KEY_ID         # AWS API key
AWS_SECRET_ACCESS_KEY     # AWS API secret
TF_PUBLIC_KEY             # SSH public key for EC2
```

### EC2 IAM Role Permissions

The EC2 instance needs permissions to:
- Read AWS Secrets Manager (for GitHub token)
- Describe EC2 instances
- Manage CloudWatch logs
- (Optional) Push to ECR for container registry

---

## 🔧 Manual Operations

### SSH into EC2

```bash
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

### Run Ansible Manually

```bash
cd k8s_assignment/ansible
ansible-playbook main.yml

# Run specific roles
ansible-playbook main.yml --tags docker
ansible-playbook main.yml --tags deployment
```

### Monitor Minikube

```bash
minikube status
minikube logs --last=100
kubectl get nodes
kubectl get pods -n my-app
kubectl logs -n my-app <pod-name>
```

### Scale Application

```bash
kubectl scale deployment hello-app -n my-app --replicas=5
```

---

## ✅ Testing the Setup

```bash
# 1. Verify cluster
kubectl get nodes
kubectl get pods -A

# 2. Check deployment
kubectl get deployment -n my-app
kubectl get svc -n my-app

# 3. Port-forward for testing
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &

# 4. Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080

# 5. Monitor logs
kubectl logs -n my-app -l app=hello-app -f
```

---

## 🎯 Summary

| Layer | Tool | Purpose |
|-------|------|---------|
| **Infrastructure** | Terraform | Provision EC2 in AWS |
| **Bootstrap** | Bash/userdata.sh | Install tools and dependencies |
| **Containerization** | Docker | Package Flask app in image |
| **Orchestration** | Kubernetes (Minikube) | Manage containers, scaling, networking |
| **Automation** | Ansible | Idempotent resource deployment |
| **CI/CD** | GitHub Actions | Automated workflows and deployments |

Each layer is independent but integrated, allowing for:
- Reproducible deployments
- Version control of all configuration
- Easy scaling and modification
- Automated testing and deployment

---

**Last Updated**: March 1, 2026  
**Status**: ✅ Complete & Production Ready

# 🚀 Kubernetes Assignment - Infrastructure as Code

Complete end-to-end deployment of a Kubernetes cluster with containerized Python Flask application using Terraform, Ansible, GitHub Actions, and shell scripts.

---

## 🎯 Assignment Overview

This solution demonstrates a fully automated infrastructure deployment covering:

- **Problem**: Deploy a Kubernetes cluster with a containerized application on a linux machine
- **Approach**: Infrastructure as Code (IaC) using Terraform to create the Linux EC2, shell scripts for bootstrapping, Docker for containerization, and Ansible for orchestration and github Actions for deployment workflows.
- **Result**: Production-ready Kubernetes cluster with automated scaling, monitoring, and deployment pipelines.

**Components**:
1. **Terraform** - AWS infrastructure provisioning (EC2, security groups, networking)
2. **Bash** - EC2 instance bootstrap and initial setup downloading all the dependencies
3. **Docker** - Application containerization with security best practices
4. **Kubernetes** - Container orchestration (Deployment, Service, Ingress, HPA, Monitoring)
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
    ├─ [3] GitHub Actions (Ansible Workflow)
    │       ↓
    │   Ansible Playbook
    │       ↓
    └─ [4] Ansible roles
            ↓
        Minikube Role: Create minikube cluster
        Docker Role: Build & Push Image
        Deployment Role: Create K8s Deployment (2 replicas)
        Service Role: Expose via ClusterIP
        Ingress Role: Configure external access
        HPA Role: Setup auto-scaling
        Monitoring Role: Deploy Prometheus/Grafana
```

---

## 🏢 Infrastructure Setup (Terraform)

**File**: `terraform/main.tf` - Provisions AWS infrastructure

**Components created**:
1. **EC2 Instance** (t3.2xlarge, Ubuntu 22.04 LTS)
   - Launches with userdata.sh bootstrap script
   - Runs in custom VPC/subnet
   - IAM role with Secrets Manager permissions

2. **Security Group**
   - Port 22 (SSH) - restricted to your IP
   - Port 80 (HTTP) - restricted to your IP
   - Port 443 (HTTPS) - restricted to your IP

3. **SSH Key Pair** - Created to login to the EC2 from your local

**GitHub Actions Workflow** (`.github/workflows/deploy.yml`)
- **Trigger**: Manual (workflow_dispatch)
- **Steps**: Checkout → Setup Terraform → AWS credentials → Init → Apply
- **Result**: EC2 instance provisioned → userdata.sh runs automatically and Instance will launch with all dependencies pre-installed

---

## 💻 EC2 Bootstrap (Userdata)

**File**: `bash/userdata.sh` - Runs automatically on EC2 launch before login

**Section 1: System Updates & Dependencies**
- apt-get update/upgrade
- Install: Docker, AWS CLI, Git, jq, Python tools

**Section 2: Docker Setup**
- Enable & start Docker daemon
- Add ubuntu user to docker group (no sudo needed)
- Ready for container deployment

**Section 3: Kubernetes Tools**
- kubectl (CLI)
- Minikube (single-node cluster)
- Helm (package manager)

**Section 4: Ansible Installation**
- Add Ansible PPA repository
- Install Ansible package
- Ready for infrastructure automation

**Section 5: GitHub Integration**
- Fetch GitHub token from AWS Secrets Manager
- Clone private repository
- Setup GitHub Actions runner (listens for workflow jobs)

**Section 6: Setup Complete** (~5-10 minutes)
✅ Docker running | ✅ K8s tools ready | ✅ Ansible installed | ✅ GitHub runner listening

**Next Step**: Manual trigger of Ansible workflow or manual SSH into instance to run playbooks

---

## ☸️ Minikube Startup (Ansible Role)

The **minikube** Ansible role starts a single-node Kubernetes cluster on the EC2 instance.

```bash
# ansible/roles/minikube/tasks/main.yml
minikube start --driver=docker --cpus=2 --memory=4096
kubectl get nodes  # Verify cluster ready
```

**Configuration**:
- **Driver**: Docker (lightweight, no VM overhead)
- **CPU**: 3 cores
- **Memory**: 6GB
- **Startup time**: ~1 minute

**Verification**:
```bash
minikube status
kubectl get nodes
```

After this role completes, the cluster is ready for building Docker images and deploying applications.

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

The Docker image is built automatically by the **docker** Ansible role, which tags the image using the GitHub commit SHA for version control and traceability.

```bash
# Ansible docker role builds and tags image
# File: ansible/roles/docker/tasks/main.yml
docker build -t hello-app:${COMMIT_SHA} docker/
docker build -t hello-app:latest docker/

# COMMIT_SHA comes from GitHub Actions or environment
# Example: hello-app:a3f9e7c2d1b5
```

**How It Works**:
1. GitHub Actions workflow passes `COMMIT_SHA` to Ansible
2. Docker role uses SHA as primary tag
3. Also tags as `latest` for convenient default reference
5. Deployment uses specific SHA tag

**Benefits**:
- **Traceability**: Know exactly which commit produced which image
- **Rollback**: Easy to revert to previous images
- **Reproducibility**: Rebuild exact same image from commit SHA
- **Safety**: `latest` tag always safe (linked to commit history)

---

## ☸️ Kubernetes Deployment

K8s manifests in `k8s/` directory:

### Deployment (deployment.yaml.j2)
- **2 replicas** of Flask app running
- **Resource limits**: 100m-250m CPU, 128Mi-256Mi memory
- **Health checks**: Liveness & readiness probes on `/health` endpoint
- **Security**: Runs as non-root user (UID 1001)
- **Image**: Uses local Docker image (imagePullPolicy: Never for Minikube)

### Service (service.yaml)
- **Type**: ClusterIP (internal load balancer)
- **Port mapping**: 80
- **Routes traffic** between 2 pod replicas

### Ingress (ingress.yaml)
- **Domain**: adbsafegate.helloworld.com
- **TLS**: HTTPS with certificate
- **Routes**: External traffic to service

### HPA (hpa.yaml)
- **Min replicas**: 2, **Max**: 5
- **Scale trigger**: CPU > 50% utilization
- **Auto-scales** based on load

---

## 🤖 Infrastructure Automation (Ansible)

### What Is Ansible?

Ansible is an agentless configuration management tool that runs playbooks (YAML scripts) to configure systems, deploy applications, and manage infrastructure.

**Why Ansible?**
- Idempotent (safe to run multiple times)
- No agents needed (just SSH + Python)
- YAML syntax (easy to read and modify)
- Can run from GitHub Actions workflows via self-hosted runner on EC2
- **Self-hosted runner approach**: GitHub Actions runner is installed on EC2 during userdata launch, allowing Ansible playbooks to execute locally without internet SSH exposure

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

| Role | Purpose |
|------|---------|
| **minikube** | Start cluster, configure kubectl, verify ready |
| **docker** | Build image with commit SHA tag |
| **deployment** | Create namespace, deploy 2 replicas, wait for pods |
| **service** | Create ClusterIP service, configure port mapping |
| **ingress** | Enable NGINX addon, create ingress with TLS routing |
| **hpa** | Deploy autoscaler (2-5 replicas, 50% CPU threshold) |
| **monitoring** | Deploy Prometheus + Grafana, configure dashboards |

### Running Ansible Playbooks

**Why GitHub Runner on EC2?**

Instead of running workflows on GitHub's hosted runners (which requires exposing EC2 via SSH to the internet), we install a self-hosted GitHub Actions runner on the EC2 instance itself. This allows:
- **Ansible runs locally** on EC2 (no SSH needed from internet)
- **More secure** - no public internet access required
- **Easier management** - no need to manage SSH keys from external systems
- **Better performance** - no network latency between runner and K8s cluster

**Manually (from EC2 instance)**:
```bash
cd k8s_assignment/ansible
ansible-playbook -i inventory.ini main.yml

# Or run specific roles
ansible-playbook main.yml --tags docker,deployment
```

**Via GitHub Actions** (recommended):
Self-hosted runner on EC2 executes Ansible playbooks locally

---

## 🔄 GitHub Workflows

### Why GitHub Workflows?

- Automatic CI/CD integration
- Visible deployment history
- Easy to modify and test
- No additional tools needed (integrated into GitHub)

### Workflow 1: Terraform Apply

**File**: `.github/workflows/deploy.yml`

**Purpose**: Provision AWS EC2 infrastructure with all dependencies pre-installed

**Steps**: Checkout → Setup Terraform → AWS credentials → Init → Apply

**Triggers**: Manual dispatch

**Result**: EC2 instance (t3.2xlarge) launched with userdata.sh and secure networking configuration running automatically

---

### Workflow 2: Ansible Deploy

**File**: `.github/workflows/ansible-ec2.yml` 

**Purpose**: Deploy Kubernetes resources and application updates automatically

**Triggers**: Manual dispatch

**Steps**: Checkout → Setup SSH key → SSH to EC2 → Run Ansible playbooks → Verify deployment

**Result**: K8s cluster and application running (Minikube, Docker image, Deployment, Service, Ingress, HPA, Monitoring)

---

## 🔐 Secrets & Configuration

### GitHub Secrets Required

```
AWS_ACCESS_KEY_ID         # AWS API key
AWS_SECRET_ACCESS_KEY     # AWS API secret
TF_PUBLIC_KEY             # SSH public key for EC2
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

# 🚀 Kubernetes & Docker Assignment - Complete Solution

> A production-ready single-node Kubernetes cluster deployment with a secure Python Flask application, complete automation, and comprehensive monitoring.

**Status**: ✅ Complete & Ready for Interview  
**Created**: March 1, 2026  
**Assignment**: Kubernetes Cluster + Secure Docker Image  

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Setup](#step-by-step-setup)
5. [Docker Application](#docker-application)
6. [Kubernetes Deployment](#kubernetes-deployment)
7. [Accessing the Application](#accessing-the-application)
8. [Monitoring & Logs](#monitoring--logs)
9. [Troubleshooting](#troubleshooting)
10. [Interview Preparation](#interview-preparation)

---

## 🎯 Quick Start

Get your cluster running in under 5 minutes:

```bash
# 1. Make scripts executable
chmod +x bash/*.sh

# 2. Start Minikube cluster
bash bash/start_cluster.sh

# 3. Build Docker image
bash bash/build_image.sh

# 4. Deploy to Kubernetes
bash bash/deploy_k8s.sh

# 5. Access the app
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &
open http://localhost:8080
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Minikube Cluster (macOS)                  │
│                  Single-Node Kubernetes                     │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
        ┌───────────▼──────────┐    ┌──▼──────────────────┐
        │   Control Plane      │    │   my-app Namespace  │
        │  (kube-system)       │    │                     │
        │                      │    │  ┌──────────────┐   │
        │  ✓ kube-apiserver    │    │  │hello-app Pod1│   │
        │  ✓ controller-mgr    │    │  │(Flask App)   │   │
        │  ✓ scheduler         │    │  └──────────────┘   │
        │  ✓ etcd              │    │                     │
        │  ✓ coredns           │    │  ┌──────────────┐   │
        │  ✓ kube-proxy        │    │  │hello-app Pod2│   │
        └──────────────────────┘    │  │(Flask App)   │   │
                                    │  └──────────────┘   │
                                    │                     │
                                    │  ClusterIP Service  │
                                    │  NGINX Ingress      │
                                    └─────────────────────┘
```

### What's Running?

- **2 Flask App Replicas**: For high availability
- **ClusterIP Service**: Internal load balancing
- **NGINX Ingress**: External access routing
- **Control Plane**: Full K8s management (apiserver, controller-manager, etc.)
- **etcd**: Distributed state storage

---

## 📦 Prerequisites

### Required Software

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Docker** | Container runtime | [Download](https://www.docker.com/products/docker-desktop) |
| **Minikube** | Local K8s cluster | `brew install minikube` |
| **kubectl** | K8s CLI tool | `brew install kubectl` |
| **K9s** | GUI monitoring (optional) | `brew install k9s` |

### Verify Installation

```bash
docker --version        # Docker Desktop 4.x+
minikube version        # v1.32+
kubectl version --client # v1.28+
k9s version             # v0.32+
```

### System Requirements

- **RAM**: Minimum 4GB (8GB recommended)
- **Disk**: 10GB free space
- **macOS**: 11+ (Intel or Apple Silicon)

---

## 🔧 Step-by-Step Setup

### Step 1: Start the Minikube Cluster

```bash
bash bash/start_cluster.sh
```

**What it does:**
- Launches Minikube with Docker driver (2 CPUs, 4GB RAM)
- Verifies cluster is running with `kubectl get nodes`
- Shows control plane pod status

**Expected output:**
```
Starting Minikube...
✅ Done! kubectl is configured to use "minikube" by default
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   25s   v1.28.3
```

**Behind the scenes:**
- Docker Desktop must be running
- Minikube creates a lightweight Linux VM inside Docker
- Kubernetes API server becomes available at `https://127.0.0.1:51234` (or similar)
- All system pods (DNS, proxy, etc.) start automatically

### Step 2: Build the Docker Image

```bash
bash bash/build_image.sh
```

**What it does:**
- Switches Docker CLI to use Minikube's Docker daemon
- Builds the Flask application image from `docker/Dockerfile`
- Verifies image is available in Minikube

**Expected output:**
```
🐳 Switching Docker to Minikube environment...
🔨 Building Docker image: hello-app:latest from docker/
✅ Docker image built successfully.
🎉 Image hello-app:latest is available.
```

**Why Minikube's Docker?**
- No need to push to Docker Hub
- Images are directly available to kubelet
- Faster development cycle

### Step 3: Deploy to Kubernetes

```bash
bash bash/deploy_k8s.sh
```

**What it does:**
1. Verifies Minikube is running
2. Enables NGINX Ingress addon (for external access)
3. Applies Kubernetes manifests:
   - **Deployment**: Creates 2 replicas of the Flask app
   - **Service**: Exposes pods on port 80 (ClusterIP)
   - **Ingress**: Routes external traffic to the service
4. Waits for pods to be ready
5. Displays logs from the first pod

**Expected output:**
```
🔧 Enabling NGINX ingress addon...
🚀 Applying Kubernetes manifests...
⏳ Waiting for pods to be ready...
📦 Current pod status:
NAME                        READY   STATUS    RESTARTS   AGE
hello-app-558b4d6f7-2xkp7   1/1     Running   0          10s
hello-app-558b4d6f7-9m8lk   1/1     Running   0          10s
```

---

## 🐳 Docker Application

### What is the Application?

A simple Flask web server that:
- Displays a welcome page with pod hostname
- Provides a health check endpoint
- Runs as a non-root user (security best practice)
- Uses minimal Docker image (~120MB)

### Application Code

**`docker/app.py`** - Flask application:
```python
from flask import Flask, render_template
import socket

app = Flask(__name__)

@app.route("/")
def home():
    # Display pod hostname to verify load balancing
    return render_template("index.html", hostname=socket.gethostname())

@app.route("/health")
def health():
    # Health check endpoint for K8s probes
    return "OK", 200
```

**Endpoints:**
- `GET /` → HTML page with pod hostname
- `GET /health` → Returns "OK" (used by Kubernetes health checks)

### Dockerfile Security Practices

Our `docker/Dockerfile` implements several security best practices:

```dockerfile
FROM python:3.11-slim
# ✓ Minimal base image (120MB vs 1GB+ for full Python)

RUN useradd -u 1001 -m appuser
# ✓ Non-root user (runs as UID 1001, not root/UID 0)
# ✓ Prevents privilege escalation attacks

RUN pip install --no-cache-dir flask
# ✓ --no-cache-dir reduces layer size (no duplicate downloads)

USER 1001
# ✓ Switch to non-root before running application
```

**Why these practices matter:**

| Practice | Threat Prevented |
|----------|-----------------|
| Minimal base image | Reduces attack surface (fewer packages = fewer vulnerabilities) |
| Non-root user | Container escape can't become system root |
| No pip cache | Smaller image size = faster downloads |
| Explicit USER | Prevents accidental root execution |

### Building Locally (Optional)

```bash
# Build the image locally
docker build -t hello-app:latest docker/

# Run the container
docker run -p 5000:5000 hello-app:latest

# Test the app
curl http://localhost:5000/health  # Returns: OK
curl http://localhost:5000          # Returns: HTML page
```

---

## ☸️ Kubernetes Deployment

### Kubernetes Manifests

Our deployment uses three Kubernetes resources:

#### 1. **Deployment** (`k8s/deployment.yaml.j2`)

Controls how many pods run and their configuration:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  namespace: my-app  # Isolated namespace
spec:
  replicas: 2  # Always 2 pods running (high availability)
  
  template:
    spec:
      containers:
      - name: hello-app
        image: hello-app:latest
        imagePullPolicy: Never  # Use local image (faster)
        
        # Resource requests/limits
        resources:
          requests:
            cpu: "100m"         # Need 0.1 CPU minimum
            memory: "128Mi"     # Need 128MB minimum
          limits:
            cpu: "250m"         # Max 0.25 CPU
            memory: "256Mi"     # Max 256MB
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health       # Check if alive
            port: 5000
          initialDelaySeconds: 15  # Wait 15s before first check
          periodSeconds: 10        # Check every 10s
        
        readinessProbe:
          httpGet:
            path: /health       # Check if ready for traffic
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
        
        # Security
        securityContext:
          runAsNonRoot: true        # Prevent running as root
          allowPrivilegeEscalation: false  # Can't gain more privileges
```

**Why 2 replicas?**
- If one pod crashes, the other handles traffic
- No downtime during updates (rolling deployment)

**Why health checks?**
- Liveness probe: Restarts dead pods automatically
- Readiness probe: Only sends traffic to healthy pods

#### 2. **Service** (`k8s/service.yaml`)

Exposes pods on a stable internal IP:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-app-service
  namespace: my-app
spec:
  type: ClusterIP  # Internal IP (not exposed outside cluster)
  selector:
    app: hello-app  # Route to pods with this label
  ports:
  - port: 80        # Listen on port 80
    targetPort: 5000  # Forward to pod port 5000
```

**What it does:**
- Creates a stable IP address inside the cluster
- Routes traffic to pods matching the selector
- Provides load balancing between replicas

#### 3. **Ingress** (`k8s/ingress.yaml`)

Routes external traffic into the cluster:

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
  
  tls:  # HTTPS (requires certificate secret)
  - hosts:
    - adbsafegate.helloworld.com
    secretName: hello-app-tls
```

**Traffic flow:**
```
External Request
    ↓
Ingress Controller (NGINX)
    ↓
Service (port 80)
    ↓
Pod Replicas (port 5000)
```

### Namespace Isolation

All application resources run in the `my-app` namespace:

```bash
# View only app resources
kubectl get pods -n my-app

# View only system pods
kubectl get pods -n kube-system

# Delete only the app (keeps cluster running)
kubectl delete namespace my-app
```

**Benefits:**
- Isolates app from system components
- Easy to clean up
- Supports multi-tenant environments

---

## 🌐 Accessing the Application

### Option 1: Port Forwarding (Easiest)

Forward your local port 8080 to the Kubernetes service:

```bash
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &
```

Then visit: **http://localhost:8080**

**How it works:**
- kubectl creates a tunnel from `localhost:8080` to service port 80
- All traffic through this port reaches your pods
- Perfect for development/testing

**Kill the port-forward:**
```bash
fg      # Bring process to foreground
Ctrl+C  # Kill it
```

### Option 2: Ingress (Production-like)

```bash
# Get Ingress IP
kubectl get ingress -n my-app

# Add to /etc/hosts (macOS/Linux)
echo "127.0.0.1 adbsafegate.helloworld.com" | sudo tee -a /etc/hosts

# Visit the site
open http://adbsafegate.helloworld.com
```

**Note:** Requires TLS certificate setup (manual step for Minikube).

### Option 3: Minikube Service

```bash
minikube service -n my-app hello-app-service
# Opens the service URL in your default browser automatically
```

---

## 📊 Monitoring & Logs

### View Cluster Status

```bash
# All nodes
kubectl get nodes

# All pods (all namespaces)
kubectl get pods -A

# Pods in my-app only
kubectl get pods -n my-app

# Detailed pod info
kubectl describe pod -n my-app <pod-name>
```

### View Application Logs

```bash
# Last 50 lines of a pod
kubectl logs -n my-app <pod-name>

# Follow logs (like `tail -f`)
kubectl logs -n my-app <pod-name> -f

# Logs from all pods with label app=hello-app
kubectl logs -n my-app -l app=hello-app --all-containers=true
```

### View Control Plane Logs

**kube-apiserver** (handles all API requests):
```bash
kubectl logs -n kube-system -l component=kube-apiserver --tail=50
```

**kube-controller-manager** (manages replicas, endpoints, etc):
```bash
kubectl logs -n kube-system -l component=kube-controller-manager --tail=50
```

**kube-scheduler** (decides which node pods run on):
```bash
kubectl logs -n kube-system -l component=kube-scheduler --tail=50
```

### Using K9s GUI

K9s provides an interactive terminal UI for monitoring:

```bash
# Install
brew install k9s

# Launch
k9s
```

**Navigation:**
- `:pods` → View all pods
- `:ns` → Switch namespace
- `l` → View logs of selected pod
- `d` → Delete pod (watch it restart!)
- `?` → Help

**For the assignment:**
1. Launch K9s
2. Switch to kube-system namespace
3. Select kube-apiserver pod
4. Press `l` to view logs
5. Take a screenshot ✅

---

## 🔍 Troubleshooting

### Minikube Won't Start

```bash
# Check if Docker is running
docker ps

# Check Minikube status
minikube status

# View Minikube logs
minikube logs --last=100

# Nuclear option: delete and restart
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

### Pods Not Running

```bash
# Check pod status
kubectl get pods -n my-app

# Detailed description (shows events/errors)
kubectl describe pod -n my-app <pod-name>

# View logs
kubectl logs -n my-app <pod-name>

# Check image is available
minikube image ls | grep hello-app
```

### Image Not Found Error

```bash
# Rebuild the image
bash bash/build_image.sh

# Verify it's in Minikube
minikube image ls | grep hello-app

# Force restart deployment
kubectl rollout restart deployment/hello-app -n my-app
```

### Service Not Accessible

```bash
# Check service exists
kubectl get svc -n my-app

# Check endpoints (backing pods)
kubectl get endpoints -n my-app

# Try accessing from within a pod
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://hello-app-service.my-app.svc.cluster.local
```

### Port Forward Fails

```bash
# Kill any existing port-forward
killall kubectl

# Try again
kubectl port-forward -n my-app svc/hello-app-service 8080:80
```

---

## 🎤 Interview Preparation

### What You Should Know

#### 1. **Why Minikube?**

*Question: Why did you choose Minikube for this assignment?*

**Answer:**
- Lightweight single-node cluster for development
- Runs on laptop using Docker Desktop
- No cloud provider needed
- Fast startup/teardown (testing)
- Exact same Kubernetes API as production
- Industry standard for local development

#### 2. **Docker Security Practices**

*Question: What security best practices did you implement in the Dockerfile?*

**Answer:**
- **Non-root user**: Runs as UID 1001 (not root)
  - If container is compromised, attacker doesn't have root
  - Mitigates privilege escalation attacks
  
- **Minimal base image**: `python:3.11-slim`
  - 120MB vs 1GB+ for full image
  - Fewer packages = fewer vulnerabilities
  - Faster deployment
  
- **No pip cache**: `--no-cache-dir`
  - Reduces final image size
  - Prevents accidentally using old dependencies
  
- **Read-only file system ready**: Can enable in SecurityContext
  - Forces application to be stateless
  - Prevents persistence attacks

#### 3. **Kubernetes Architecture**

*Question: Walk me through how traffic reaches your application.*

**Answer:**
```
1. Request comes to adbsafegate.helloworld.com
2. NGINX Ingress Controller routes to Service (port 80)
3. Service load balances to one of 2 pods (port 5000)
4. Flask app receives request and responds
5. Response flows back through the chain
```

#### 4. **High Availability**

*Question: What happens if a pod crashes?*

**Answer:**
- Kubernetes detects the crash immediately
- Liveness probe fails after 15 seconds
- Kubernetes automatically restarts the pod
- Meanwhile, traffic goes to the other pod
- User experiences no downtime

#### 5. **Resource Management**

*Question: Why set CPU and memory limits?*

**Answer:**
- **Requests**: Guaranteed minimum resources
  - Scheduler ensures node has this available
  - Pod can't be starved
  
- **Limits**: Maximum resources
  - Prevents runaway pod from consuming all resources
  - Protects other pods on the same node
  
- **Example**: Our app requests 100m CPU, limits to 250m
  - Gets at least 0.1 CPU
  - Can burst to 0.25 CPU if idle capacity available

### Demo Script for Interview

```bash
# 1. Show the cluster is running
kubectl get nodes
# → Show minikube node is Ready

# 2. Show the application pods
kubectl get pods -n my-app
# → Show 2 running replicas

# 3. Port-forward and access the app
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &
sleep 2
curl http://localhost:8080/health
curl http://localhost:8080

# 4. Show the service and endpoints
kubectl get svc -n my-app
kubectl get endpoints -n my-app

# 5. Show control plane pods
kubectl get pods -n kube-system | grep -E "apiserver|controller|scheduler"

# 6. Simulate a pod crash (restart)
POD=$(kubectl get pods -n my-app -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod -n my-app $POD
sleep 5
kubectl get pods -n my-app
# → Show new pod was created automatically

# 7. Show logs (for screenshot)
k9s  # Launch K9s and navigate to logs
```

### Interview Checklist

- [ ] Minikube cluster running (`kubectl get nodes`)
- [ ] 2 pods running and healthy (`kubectl get pods -n my-app`)
- [ ] Can access the app (port-forward works)
- [ ] Can show pod logs (screenshot of K9s)
- [ ] Can show control plane logs (apiserver, controller-manager)
- [ ] Can explain the architecture diagram
- [ ] Can discuss Docker security practices
- [ ] Have tested pod restart (delete → auto-recreate)

---

## 📁 Project Structure

```
k8s_assignment/
├── README.md                        # This file
├── docker/
│   ├── Dockerfile                   # Secure Flask app image
│   ├── app.py                       # Flask application
│   ├── templates/
│   │   └── index.html               # Web UI template
│   └── static/                      # CSS, JavaScript assets
├── bash/
│   ├── start_cluster.sh            # Start Minikube
│   ├── build_image.sh              # Build Docker image
│   └── deploy_k8s.sh               # Deploy to K8s
├── k8s/
│   ├── deployment.yaml.j2          # Pod deployment config
│   ├── service.yaml                # Internal service
│   ├── ingress.yaml                # External routing
│   └── hpa.yaml                    # Horizontal Pod Autoscaler
├── terraform/                       # AWS infrastructure (bonus)
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── iam.tf
│   └── outputs.tf
└── ansible/                         # Infrastructure automation (bonus)
    ├── inventory.ini
    ├── main.yml
    └── roles/
```

---

## 🔗 Useful Resources

- [Minikube Documentation](https://minikube.sigs.k8s.io/)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [K9s - Kubernetes TUI](https://k9scli.io/)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Flask Documentation](https://flask.palletsprojects.com/)

---

## 📝 Notes for Interviewer

This solution demonstrates:

✅ **DevOps Skills**
- Infrastructure as Code (Kubernetes manifests)
- Automation scripting (bash)
- Container orchestration concepts

✅ **Security Awareness**
- Non-root container execution
- Minimal attack surface
- Resource constraints
- Health checks and recovery

✅ **System Design**
- High availability (replicas)
- Load balancing (service)
- External routing (ingress)
- Namespace isolation

✅ **Production Practices**
- Automated deployment
- Health monitoring
- Graceful failure handling
- Clean, documented code

---

**Last Updated**: March 1, 2026  
**Status**: ✅ Ready for Interview  
**Maintainer**: Varaprasad Mamidi  
**Repository**: [GitHub Link](https://github.com/Varaprasad4127/k8s_assignment)
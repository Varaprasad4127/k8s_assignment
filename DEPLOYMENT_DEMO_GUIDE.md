# 🚀 Deployment & Access Demo Guide

Step-by-step demonstration of deploying the Kubernetes cluster and accessing the automated application with visual results.

---

## 📋 Prerequisites

Before starting this demo, ensure you have:
- GitHub secrets configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, TF_PUBLIC_KEY)
- GitHub token stored in AWS Secrets Manager as `github-token-delete-me`
- SSH key pair created locally

---

## Demo Phase 1: Infrastructure Deployment (Terraform)

### Step 1: Trigger Terraform Workflow

**Action**: Go to GitHub repository → Actions tab → Select "Terraform Apply" → Click "Run workflow"

**Expected Result**: Workflow starts and provisions AWS infrastructure

**Screenshot**: [Terraform Workflow Running](./screenshots/01-terraform-workflow-running.png)

---

### Step 2: Monitor Terraform Execution

**Duration**: ~5 minutes

**What happens**:
- Terraform checks AWS credentials
- Creates VPC and security groups
- Launches EC2 instance (t3.2xlarge, Ubuntu 22.04)
- Attaches IAM role with Secrets Manager permissions
- Executes userdata.sh automatically on instance launch

**Workflow shows**:
```
✓ Checkout code
✓ Setup Terraform
✓ Configure AWS credentials
✓ Terraform init
✓ Terraform apply
```

**Screenshot**: [Terraform Workflow Complete](./screenshots/02-terraform-workflow-complete.png)

---

### Step 3: Verify EC2 Instance is Running

**Action**: AWS Console → EC2 → Instances

**Expected Result**: 
- EC2 instance appears in "Running" state
- Public IP address assigned
- Status checks: "2/2 passed"
- Instance type: t3.2xlarge

**Screenshot**: [EC2 Instance Running](./screenshots/03-ec2-instance-running.png)

---

### Step 4: Wait for Userdata Script Completion

**Duration**: ~5-10 minutes

The EC2 instance automatically installs all dependencies:
- ✅ Docker installed & running
- ✅ Kubernetes tools (kubectl, Minikube, Helm)
- ✅ Ansible installed
- ✅ GitHub Actions runner registered
- ✅ Repository cloned

**Action**: SSH into EC2 to verify

```bash
ssh -i ~/.ssh/k8s_assignment_key ubuntu@<EC2_PUBLIC_IP>

# Verify tools installed
docker --version        # Docker version X.X.X
kubectl version         # Client version X.X.X
minikube version        # v1.X.X
ansible --version       # ansible X.X.X
```

**Screenshot**: [Tools Verification](./screenshots/04-tools-verification.png)

---

## Demo Phase 2: Kubernetes Cluster Deployment (Ansible)

### Step 5: Trigger Ansible Workflow

**Action**: GitHub repository → Actions tab → Select "Ansible Deploy" → Click "Run workflow"

**Alternative**: Manually SSH and run:
```bash
cd k8s_assignment/ansible
ansible-playbook main.yml
```

**Expected Result**: Ansible playbook starts executing 7 roles sequentially

**Screenshot**: [Ansible Workflow Triggered](./screenshots/05-ansible-workflow-triggered.png)

---

### Step 6: Monitor Role Execution

**Duration**: ~10 minutes total

The workflow executes roles in this order:

#### Role 1: Minikube (1-2 minutes)
```
TASK [minikube : Start Minikube cluster]
minikube start --driver=docker --cpus=2 --memory=4096
✓ Cluster created successfully
✓ kubectl context switched to minikube
```

**Screenshot**: [Minikube Started](./screenshots/06-minikube-started.png)

#### Role 2: Docker (2-3 minutes)
```
TASK [docker : Build Docker image]
docker build -t hello-app:${COMMIT_SHA} docker/
✓ Image built: hello-app:a3f9e7c2d1b5
✓ Also tagged as: hello-app:latest
```

**Screenshot**: [Docker Image Built](./screenshots/07-docker-image-built.png)

#### Role 3: Deployment (1-2 minutes)
```
TASK [deployment : Create namespace]
✓ Namespace 'my-app' created

TASK [deployment : Deploy application]
✓ Deployment created with 2 replicas
✓ Pods starting...
```

**Screenshot**: [Deployment Created](./screenshots/08-deployment-created.png)

#### Roles 4-7: Service, Ingress, HPA, Monitoring (2-3 minutes)
```
✓ ClusterIP service created (port 80→5000)
✓ NGINX ingress configured
✓ HPA deployed (2-5 replicas, 50% CPU)
✓ Prometheus + Grafana deployed
```

**Screenshot**: [All Resources Deployed](./screenshots/09-all-resources-deployed.png)

---

### Step 7: Verify Complete Deployment

**Action**: SSH into EC2 and run verification commands

```bash
kubectl cluster-info
```

**Expected Output**:
```
Kubernetes control-plane is running at https://192.168.49.2:6443
CoreDNS is running at https://192.168.49.2:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

**Screenshot**: [Cluster Info](./screenshots/10-cluster-info.png)

---

### Step 8: Check Kubernetes Resources

```bash
kubectl get nodes
```

**Expected Output**:
```
NAME       STATUS   ROLES           AGE     VERSION
minikube   Ready    control-plane   5m30s   v1.28.3
```

**Screenshot**: [Nodes Status](./screenshots/11-nodes-status.png)

---

### Step 9: Verify Deployment Status

```bash
kubectl get deployment -n my-app
```

**Expected Output**:
```
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
hello-app   2/2     2            2           3m
```

**Screenshot**: [Deployment Ready](./screenshots/12-deployment-ready.png)

---

### Step 10: Check Running Pods

```bash
kubectl get pods -n my-app
```

**Expected Output**:
```
NAME                         READY   STATUS    RESTARTS   AGE
hello-app-7d8f4c9b9-abc12    1/1     Running   0          3m
hello-app-7d8f4c9b9-xyz99    1/1     Running   0          3m
```

**Screenshot**: [Pods Running](./screenshots/13-pods-running.png)

---

### Step 11: Verify Docker Image

```bash
docker images | grep hello-app
```

**Expected Output**:
```
hello-app          a3f9e7c2d1b5   2 minutes ago   125MB
hello-app          latest         2 minutes ago   125MB
```

**Screenshot**: [Docker Image Verified](./screenshots/14-docker-image-verified.png)

---

## Demo Phase 3: Access & Test Application

### Step 12: Port Forward Service

```bash
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &
```

**Expected Result**: Port forwarding established

```
Forwarding from 127.0.0.1:8080 -> 5000
Forwarding from [::1]:8080 -> 5000
```

**Screenshot**: [Port Forwarding Active](./screenshots/15-port-forwarding-active.png)

---

### Step 13: Test Health Endpoint

```bash
curl http://localhost:8080/health
```

**Expected Output**: `OK`

**Screenshot**: [Health Check Passed](./screenshots/16-health-check-passed.png)

---

### Step 14: Test Application Endpoint

```bash
curl http://localhost:8080
```

**Expected Output**: HTML page with pod hostname

```html
<html>
<body>
<h1>Hello from Kubernetes!</h1>
<p>Pod hostname: hello-app-7d8f4c9b9-abc12</p>
</body>
</html>
```

**Screenshot**: [Application Response HTML](./screenshots/17-application-response-html.png)

---

### Step 15: Load Balancing Test

**Run multiple requests** and observe different pod hostnames:

```bash
for i in {1..10}; do curl http://localhost:8080 | grep -o "hello-app-[a-z0-9]*"; done
```

**Expected Output**: Alternating pod names showing load balancing

```
hello-app-7d8f4c9b9-abc12
hello-app-7d8f4c9b9-xyz99
hello-app-7d8f4c9b9-abc12
hello-app-7d8f4c9b9-xyz99
...
```

**Screenshot**: [Load Balancing Working](./screenshots/18-load-balancing-working.png)

---

## Demo Phase 4: Monitoring & Scaling

### Step 16: Check Service Details

```bash
kubectl get svc -n my-app
```

**Expected Output**:
```
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
hello-app-service    ClusterIP   10.96.245.123   <none>        80/TCP    4m
```

**Screenshot**: [Service Details](./screenshots/19-service-details.png)

---

### Step 17: View Ingress Configuration

```bash
kubectl get ingress -n my-app
```

**Expected Output**:
```
NAME                CLASS   HOSTS                          ADDRESS         PORTS
hello-app-ingress   nginx   adbsafegate.helloworld.com     192.168.49.1   80, 443
```

**Screenshot**: [Ingress Configured](./screenshots/20-ingress-configured.png)

---

### Step 18: Check HPA Status

```bash
kubectl get hpa -n my-app
```

**Expected Output**:
```
NAME              REFERENCE                 TARGETS   MINMAX      REPLICAS   AGE
hello-app-hpa     Deployment/hello-app      12%/50%   2/5         2          4m
```

**Screenshot**: [HPA Status](./screenshots/21-hpa-status.png)

---

### Step 19: View Application Logs

```bash
kubectl logs -n my-app -l app=hello-app --tail=20 -f
```

**Expected Output**:
```
* Running on http://0.0.0.0:5000
* WARNING: This is a development server. Do not use it in production.
```

**Screenshot**: [Application Logs](./screenshots/22-application-logs.png)

---

### Step 20: Describe Pod for Details

```bash
kubectl describe pod -n my-app hello-app-7d8f4c9b9-abc12
```

**Shows**:
- Container status: Running
- Ready probe: Success
- Liveness probe: Success
- Resource usage: CPU/Memory
- Recent events

**Screenshot**: [Pod Details](./screenshots/23-pod-details.png)

---

## Demo Phase 5: Scaling Demonstration

### Step 21: Scale Application Manually

```bash
kubectl scale deployment hello-app -n my-app --replicas=4
```

**Expected Result**: Deployment scales from 2 to 4 replicas

**Screenshot**: [Scaling Command](./screenshots/24-scaling-command.png)

---

### Step 22: Watch Scaling in Progress

```bash
kubectl get pods -n my-app -w
```

**Expected Output** (shows pods being created):
```
NAME                         READY   STATUS              RESTARTS   AGE
hello-app-7d8f4c9b9-abc12    1/1     Running             0          10m
hello-app-7d8f4c9b9-xyz99    1/1     Running             0          10m
hello-app-7d8f4c9b9-new11    0/1     ContainerCreating   0          5s
hello-app-7d8f4c9b9-new22    0/1     ContainerCreating   0          5s
...
hello-app-7d8f4c9b9-new11    1/1     Running             0          10s
hello-app-7d8f4c9b9-new22    1/1     Running             0          15s
```

**Screenshot**: [Scaling in Progress](./screenshots/25-scaling-in-progress.png)

---

### Step 23: Verify All 4 Pods Running

```bash
kubectl get pods -n my-app
```

**Expected Output**:
```
NAME                         READY   STATUS    RESTARTS   AGE
hello-app-7d8f4c9b9-abc12    1/1     Running   0          11m
hello-app-7d8f4c9b9-xyz99    1/1     Running   0          11m
hello-app-7d8f4c9b9-new11    1/1     Running   0          1m
hello-app-7d8f4c9b9-new22    1/1     Running   0          1m
```

**Screenshot**: [4 Pods Running](./screenshots/26-4-pods-running.png)

---

### Step 24: Load Balancing with 4 Replicas

```bash
for i in {1..12}; do curl -s http://localhost:8080 | grep -o "hello-app-[a-z0-9]*"; done
```

**Expected Output**: All 4 pods getting traffic

```
hello-app-7d8f4c9b9-abc12
hello-app-7d8f4c9b9-new11
hello-app-7d8f4c9b9-xyz99
hello-app-7d8f4c9b9-new22
hello-app-7d8f4c9b9-abc12
...
```

**Screenshot**: [Load Balanced to 4 Pods](./screenshots/27-load-balanced-4-pods.png)

---

## Demo Phase 6: Monitoring Stack

### Step 25: Access Minikube Dashboard

```bash
minikube dashboard &
```

Accessible at: `http://localhost:8001`

**Shows**:
- Cluster overview
- Node status
- Pod status
- Resource usage
- Logs viewer

**Screenshot**: [Minikube Dashboard](./screenshots/28-minikube-dashboard.png)

---

### Step 26: Access Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &
```

Accessible at: `http://localhost:9090`

**Shows**:
- Metrics graphs
- Query browser
- Target status
- Alerts

**Screenshot**: [Prometheus Metrics](./screenshots/29-prometheus-metrics.png)

---

### Step 27: Access Grafana

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80 &
```

Accessible at: `http://localhost:3000`

**Login**: admin / prom-operator

**Shows**:
- Pre-built dashboards
- CPU/Memory usage
- Pod metrics
- Cluster health

**Screenshot**: [Grafana Dashboard](./screenshots/30-grafana-dashboard.png)

---

## Demo Phase 7: Application Update

### Step 28: Modify Application Code

Edit `docker/app.py`:

```python
@app.route("/")
def home():
    hostname = socket.gethostname()
    return render_template("index.html", hostname=hostname, version="v2.0")
```

---

### Step 29: Commit and Push Changes

```bash
git add docker/app.py
git commit -m "Update app to version 2.0"
git push origin main
```

**Screenshot**: [Code Changes Pushed](./screenshots/31-code-changes-pushed.png)

---

### Step 30: Trigger Ansible Workflow

The workflow automatically triggers on push to main branch.

**Action**: GitHub → Actions tab → Watch "Ansible Deploy" workflow

**What happens**:
1. GitHub runner on EC2 picks up the workflow
2. Rebuilds Docker image with new commit SHA
3. Pulls new image in K8s
4. Rolling update of pods

**Screenshot**: [Auto Deploy Triggered](./screenshots/32-auto-deploy-triggered.png)

---

### Step 31: Watch Rolling Update

```bash
kubectl rollout status deployment/hello-app -n my-app -w
```

**Expected Output**:
```
Waiting for deployment "hello-app" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "hello-app" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "hello-app" rollout to finish: 4 out of 4 new replicas have been updated...
deployment "hello-app" successfully rolled out
```

**Screenshot**: [Rolling Update Complete](./screenshots/33-rolling-update-complete.png)

---

### Step 32: Verify New Version Running

```bash
curl http://localhost:8080 | grep version
```

**Expected Output**: Shows new version in response

**Screenshot**: [New Version Running](./screenshots/34-new-version-running.png)

---

## Summary Results

| Component | Status | Evidence |
|-----------|--------|----------|
| EC2 Instance | ✅ Running | Screenshot 03 |
| Minikube Cluster | ✅ Ready | Screenshot 10 |
| Docker Image | ✅ Built | Screenshot 07 |
| Application Pods | ✅ Running (4 replicas) | Screenshot 26 |
| Service | ✅ LoadBalancing | Screenshot 27 |
| Ingress | ✅ Configured | Screenshot 20 |
| HPA | ✅ Active | Screenshot 21 |
| Health Check | ✅ Passing | Screenshot 16 |
| Application | ✅ Responsive | Screenshot 17 |
| Load Balancing | ✅ Working | Screenshot 27 |
| Monitoring | ✅ Collecting metrics | Screenshot 29 |
| Auto-scaling | ✅ Configured | Screenshot 21 |
| Auto-deploy | ✅ Working | Screenshots 31-34 |

---

## Quick Command Reference

```bash
# Deployment status
kubectl get all -n my-app

# View logs
kubectl logs -n my-app -l app=hello-app -f

# Scale replicas
kubectl scale deployment hello-app -n my-app --replicas=10

# Restart pods
kubectl rollout restart deployment/hello-app -n my-app

# Port forward
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &

# Test application
curl http://localhost:8080/health
curl http://localhost:8080

# Cluster info
kubectl cluster-info
kubectl top nodes
kubectl top pods -n my-app
```

---

**Last Updated**: March 1, 2026  
**Execution Time**: ~25-30 minutes total  
**Screenshots**: 34 images demonstrating complete workflow  
**Status**: ✅ Ready for Demo

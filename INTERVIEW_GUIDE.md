# 🎤 Interview Preparation & Demo Guide

Complete walkthrough for demonstrating your Kubernetes assignment during the interview.

---

## 📋 Pre-Interview Checklist

### Week Before Interview

- [ ] **Test the setup**
  - [ ] Minikube cluster starts cleanly
  - [ ] All scripts run without errors
  - [ ] Application is accessible
  - [ ] Can view logs in K9s

- [ ] **Review documentation**
  - [ ] Read through README.md
  - [ ] Understand DOCKER_GUIDE.md
  - [ ] Study KUBERNETES_GUIDE.md
  - [ ] Familiarize with this file

- [ ] **Practice the demo**
  - [ ] Run setup multiple times
  - [ ] Time each step (know how long it takes)
  - [ ] Identify potential issues
  - [ ] Have troubleshooting commands ready

- [ ] **Prepare talking points**
  - [ ] Why Minikube?
  - [ ] Docker security practices
  - [ ] K8s architecture decisions
  - [ ] What would you do differently in production?

### Day Before Interview

- [ ] **Delete and recreate cluster**
  ```bash
  minikube delete
  minikube start --driver=docker --cpus=2 --memory=4096
  ```
  - Ensure clean state
  - No leftover resources

- [ ] **Run through full demo**
  - [ ] Time the setup
  - [ ] Verify all endpoints work
  - [ ] Test K9s access
  - [ ] Prepare screenshot locations

- [ ] **Prepare environment**
  - [ ] Close unnecessary applications (free RAM)
  - [ ] Have terminal ready
  - [ ] K9s installed and working
  - [ ] curl available

### Morning of Interview

- [ ] **System check**
  - [ ] Docker Desktop running
  - [ ] Minikube status: `minikube status`
  - [ ] kubectl working: `kubectl version --client`
  - [ ] Internet connection stable

- [ ] **Start fresh cluster**
  ```bash
  # Ensure clean state
  minikube start
  bash bash/start_cluster.sh
  bash bash/build_image.sh
  bash bash/deploy_k8s.sh
  ```

- [ ] **Verify everything**
  ```bash
  kubectl get pods -n my-app
  kubectl get svc -n my-app
  curl http://localhost:8080/health  # After port-forward
  ```

---

## ⏱️ Demo Timeline

**Total time: ~8-10 minutes**

### 1. Introduction (1 minute)

```
"I've built a complete Kubernetes deployment on Minikube 
with a secure Docker application. Let me walk you through 
the architecture and demonstrate it working."

Visual aid: Show README.md architecture diagram
```

### 2. Architecture Explanation (2 minutes)

**Talking points:**

```
"The setup consists of three main components:

1. DOCKER APPLICATION
   - Flask web server (app.py)
   - Shows pod hostname (proves load balancing)
   - Health endpoint for K8s probes
   - Runs as non-root user (security)

2. KUBERNETES DEPLOYMENT
   - 2 pod replicas for high availability
   - Service for internal load balancing
   - Ingress for external access
   - Health checks (liveness & readiness)
   - Resource limits (CPU/memory)

3. MINIKUBE CLUSTER
   - Single-node cluster on Docker
   - Development/testing purpose
   - Same API as production K8s"

Show: architecture diagram from README
```

### 3. Show the Cluster (1-2 minutes)

```bash
# Show cluster status
kubectl get nodes
# Output shows: minikube node is Ready

echo "---"

# Show running pods
kubectl get pods -n my-app
# Output shows: 2 hello-app pods Running

echo "---"

# Show services
kubectl get svc -n my-app
# Output shows: hello-app-service ClusterIP:80

echo "---"

# Show control plane
kubectl get pods -n kube-system | grep -E "apiserver|controller|scheduler|etcd"
# Shows the key control plane components
```

**What to narrate:**
```
"Here you can see:
1. The cluster has one node (Minikube)
2. Two application pods are running (app namespace)
3. Service is exposing them internally
4. Control plane pods are all healthy"
```

### 4. Access the Application (1 minute)

```bash
# Terminal 1: Start port-forward
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &
sleep 2

# Terminal 2: Test endpoints
curl http://localhost:8080/health
# Output: OK

echo "---"

curl http://localhost:8080
# Output: HTML with pod hostname

# Refresh multiple times
curl http://localhost:8080 | grep "Pod:"
curl http://localhost:8080 | grep "Pod:"
curl http://localhost:8080 | grep "Pod:"
# Shows different hostnames (load balancing!)
```

**What to narrate:**
```
"The application is working and:
1. Health endpoint responds (used by K8s)
2. Main page shows pod hostname
3. Hostname changes with each request (load balancing working!)
4. Service is properly routing traffic"
```

### 5. Demonstrate Resilience (1-2 minutes)

```bash
# Show current pods
kubectl get pods -n my-app
# Note: pod names and ages

# Delete one pod
POD=$(kubectl get pods -n my-app -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod -n my-app $POD

# Watch it restart
sleep 3
kubectl get pods -n my-app
# New pod has newer AGE, different name

# Service still works!
curl http://localhost:8080/health
# Still returns OK (didn't even notice the pod restart!)
```

**What to narrate:**
```
"This demonstrates high availability:
1. I deleted one pod intentionally
2. Kubernetes detected the issue
3. Deployment created a new pod automatically
4. Service kept routing to the healthy pod
5. Application had zero downtime

In production, this happens automatically 
when pods crash or nodes fail."
```

### 6. Show Logs (1-2 minutes)

```bash
# Option 1: kubectl
kubectl logs -n my-app <pod-name> --tail=20

# Option 2: K9s (for interview screenshot)
k9s
# Navigate: :pods → hello-app pod → l (logs)
# Shows real-time logs
# Take screenshot of logs for assignment
```

**What to narrate:**
```
"Here are the application logs showing:
1. When the pod started
2. The Flask server initialization
3. Each HTTP request received
4. Probe checks from Kubernetes

In production, these logs would go to 
a centralized logging service (ELK, Splunk, etc.)"
```

---

## 🎓 Key Questions & Answers

### Q1: "Why Minikube?"

**Answer:**
```
"Minikube is the standard tool for local Kubernetes development because:

1. Lightweight: Runs in Docker on laptop (vs requiring cloud resources)
2. Identical API: Uses exact same Kubernetes as production
3. Fast feedback: Can test changes in seconds
4. No cost: Completely free
5. Multi-platform: Works on macOS, Linux, Windows

For this assignment, it's perfect because:
- Demonstrates K8s knowledge without needing AWS access
- Can run full demo even with no internet
- Easy to reset and retry
- Industry standard (actual developers use this daily)"
```

### Q2: "What Docker security practices did you use?"

**Answer:**
```
"Four key security practices:

1. MINIMAL BASE IMAGE (python:3.11-slim)
   - 120MB vs 1GB+ for full Python
   - Fewer packages = fewer vulnerabilities
   - Reduces attack surface
   
2. NON-ROOT USER
   - Container runs as UID 1001 (appuser)
   - Not as root (UID 0)
   - If compromised: attacker has limited access
   - Can't install packages, modify system
   
3. NO PIP CACHE
   - pip install --no-cache-dir
   - Prevents stale dependencies in image
   - Reduces image size (no wasted cache)
   
4. EXPLICIT SECURITY CONTEXT
   - runAsNonRoot: true (enforced by K8s)
   - allowPrivilegeEscalation: false
   - readOnlyRootFilesystem: possible
   - Blocks privilege escalation attempts

In production, I'd add:
- Distroless base images (even smaller)
- Vulnerability scanning (Trivy)
- Image signing
- Runtime security monitoring"
```

### Q3: "How does traffic reach your app?"

**Answer:**
```
"The path is:

1. INGRESS CONTROLLER
   - NGINX controller listens on port 80/443
   - Looks at hostname: adbsafegate.helloworld.com
   - Routes based on rules defined in Ingress manifest

2. SERVICE (ClusterIP)
   - Receives traffic from Ingress
   - Has stable internal IP (10.0.0.1)
   - Selector matches pods: app=hello-app
   - Finds 2 pod endpoints

3. LOAD BALANCING
   - Service uses round-robin by default
   - Each request → different pod
   - Achieved by cycling through endpoints
   
4. POD (Flask Container)
   - Container listens on 5000
   - Receives HTTP request
   - Flask app processes
   - Returns response

This chain ensures:
- Multiple pods can handle traffic
- Single pod failure doesn't impact availability
- Easy to scale (just change replicas: 10)
- External access doesn't expose pods directly"
```

### Q4: "What happens if a pod crashes?"

**Answer:**
```
"The system automatically detects and recovers:

SCENARIO: Pod crashes

1. POD CRASH
   - Process dies (segfault, panic, etc.)
   - Container stops

2. KUBERNETES DETECTS
   - Liveness probe fails (no response to /health)
   - Deployment notices replica count mismatch
   - Current: 1 pod, Desired: 2 pods

3. AUTOMATIC RESTART
   - Deployment creates new pod
   - Scheduler places it on available node
   - Container starts fresh (clean state)

4. READINESS CHECK
   - New pod becomes Ready after health checks pass
   - Service adds it back to endpoints
   - Traffic flows to it

RESULT: Seamless recovery, zero downtime
- Other pod handled traffic throughout
- User didn't notice anything
- System self-healed"
```

### Q5: "Why set resource limits?"

**Answer:**
```
"Resource management prevents two problems:

PROBLEM 1: Scheduler placement
Without requests:
  - Scheduler doesn't know pod needs 100MB RAM
  - Places pod on node with only 50MB free
  - Pod gets OOMKilled immediately

With requests:
  - Scheduler knows pod needs 100MB
  - Only places on nodes with 100MB available
  - Pod gets guaranteed minimum resources

PROBLEM 2: Runaway processes
Without limits:
  - Buggy pod uses all node CPU/memory
  - Other pods starve
  - Node becomes unresponsive

With limits:
  - Pod can use max 250m CPU
  - Pod can use max 256MB RAM
  - If exceeded, CPU throttles, RAM OOMKills
  - Other pods protected

EXAMPLE: Our settings
  requests: 100m CPU, 128Mi RAM (guaranteed minimum)
  limits: 250m CPU, 256Mi RAM (maximum allowed)
  
This allows:
  - Pod needs at least 100m to run
  - Can burst to 250m under load
  - Can't consume entire node
  - Fair sharing with other pods"
```

### Q6: "What would you do differently in production?"

**Answer:**
```
"Several improvements for production:

1. CONTAINER REGISTRY
   - Push image to DockerHub/ECR
   - Use image digest (not 'latest' tag)
   - Version images properly

2. PERSISTENT STORAGE
   - Add PersistentVolume for data
   - Use cloud storage (EBS, S3)
   - Back up regularly

3. NETWORKING
   - NetworkPolicies (restrict pod-to-pod traffic)
   - Service mesh (Istio/Linkerd)
   - TLS between services

4. OBSERVABILITY
   - Prometheus for metrics
   - ELK/Splunk for centralized logs
   - Jaeger for distributed tracing
   - Alerts for anomalies

5. SECURITY
   - Pod Security Policies
   - RBAC (role-based access control)
   - Secrets management (Vault)
   - Network encryption

6. DEPLOYMENT
   - GitOps (ArgoCD, Flux)
   - Automated testing in CI/CD
   - Canary deployments
   - Feature flags

7. SCALING
   - Horizontal Pod Autoscaler (HPA)
   - Auto-scale based on metrics
   - Cluster autoscaling (add/remove nodes)

8. DISASTER RECOVERY
   - Multi-region deployment
   - Regular backups
   - Failover testing
   - SLA monitoring"
```

### Q7: "Describe the health checks"

**Answer:**
```
"Two probes work together:

LIVENESS PROBE
- Checks if pod is alive
- Makes HTTP GET to /health every 10s
- If fails 3 times: pod is restarted
- Use case: Detect hung processes
  
  Timeline:
  0s:    Pod starts
  15s:   First check (initialDelaySeconds)
  25s:   Check again (every 10s)
  35s:   Check again
  ...
  If response fails:
    45s: Pod restarted

READINESS PROBE
- Checks if pod can handle traffic
- Makes HTTP GET to /health every 5s
- If fails: pod removed from service
- If succeeds again: pod added back
- Use case: Pod temporarily unavailable

  Timeline:
  0s:    Pod starts
  5s:    First check
  10s:   Check again
  ...
  If /health returns 500:
    Pod status: NotReady
    Service: Endpoints updated (pod removed)
    Traffic: Goes to other pod only
  
  Once /health returns 200:
    Pod status: Ready
    Service: Endpoints updated (pod added back)
    Traffic: Resumes

REAL WORLD EXAMPLE
Pod database connection fails:
  /health → 500 error
  Readiness probe fails
  Pod removed from service
  Traffic goes to pod 2
  User doesn't see error!
  
  Pod reconnects to database:
  /health → 200 OK
  Readiness probe succeeds
  Pod added back to service
  Traffic resumes
  Recovery complete!"
```

---

## 🎬 Live Demo Script

### Pre-demo (5 mins before)

```bash
# Terminal 1: Verify everything
kubectl get pods -n my-app
kubectl get svc -n my-app
kubectl get nodes

# Terminal 2: Prepare port-forward
cd ~/Desktop/Assignment-adbsafegate/k8s_assignment

# Terminal 3: Ready to open K9s
# Don't open yet, only when showing logs
```

### During demo (follow this exactly)

```bash
# STEP 1: Show architecture (narrate for 30s)
# Point to README.md architecture diagram

# STEP 2: Show cluster status
echo "=== CLUSTER STATUS ==="
kubectl get nodes
echo ""
kubectl get pods -A | head -20  # Show some kube-system pods too
echo ""
kubectl get pods -n my-app
echo ""

# STEP 3: Show services
echo "=== SERVICES ==="
kubectl get svc -n my-app
echo ""

# STEP 4: Port-forward and test
echo "=== TESTING APPLICATION ==="
# In terminal 1, start port-forward
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &
PF_PID=$!
sleep 2

# Test health
echo "Testing /health endpoint:"
curl -s http://localhost:8080/health
echo ""

# Test load balancing (run 3 times)
echo "Testing load balancing (hostname changes):"
for i in {1..3}; do
  curl -s http://localhost:8080 | grep "Pod:"
done
echo ""

# STEP 5: Demonstrate resilience
echo "=== TESTING RESILIENCE ==="
echo "Before deletion:"
kubectl get pods -n my-app

POD=$(kubectl get pods -n my-app -o jsonpath='{.items[0].metadata.name}')
echo ""
echo "Deleting pod: $POD"
kubectl delete pod -n my-app $POD
echo ""

echo "Waiting 3 seconds..."
sleep 3

echo "After deletion (new pod created):"
kubectl get pods -n my-app

echo ""
echo "Application still works:"
curl -s http://localhost:8080/health

# STEP 6: Show logs
echo ""
echo "=== SHOWING LOGS (using K9s) ==="
echo "Launching K9s for logs visualization..."
# k9s
# Navigate in K9s: :ns → my-app → pods → select pod → l (logs)
# Take screenshot

# Cleanup
kill $PF_PID
```

---

## 📸 Screenshots for Assignment

### Screenshot 1: Cluster Status
```bash
kubectl get nodes
kubectl get pods -n my-app
kubectl get pods -n kube-system | grep -E "apiserver|controller"
```

### Screenshot 2: Application Working
```bash
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &
curl http://localhost:8080/health
curl http://localhost:8080 | grep Pod
```

### Screenshot 3: K9s Control Plane Logs ⭐ REQUIRED
```bash
k9s
# Navigate: :ns → kube-system → select kube-apiserver → l
# Take screenshot showing pod logs
```

### Screenshot 4: Resilience Test
```bash
kubectl get pods -n my-app  # Before delete
kubectl delete pod -n my-app <pod-name>
sleep 3
kubectl get pods -n my-app  # After delete (new pod created)
```

---

## ⚡ Troubleshooting During Demo

### Pod Not Ready

```bash
# Check events
kubectl describe pod -n my-app <pod-name>

# Check logs
kubectl logs -n my-app <pod-name>

# Common issue: Image not found
minikube image ls | grep hello-app
# If not there: bash bash/build_image.sh

# Restart deployment
kubectl rollout restart deployment/hello-app -n my-app
```

### Port-Forward Not Working

```bash
# Kill existing port-forward
killall kubectl

# Try again
kubectl port-forward -n my-app svc/hello-app-service 8080:80
```

### K9s Not Showing Logs

```bash
# Close K9s (Ctrl+C)
# Try kubectl directly
kubectl logs -n kube-system -l component=kube-apiserver

# If still not working: logs might be empty
# That's okay, show service logs instead
kubectl logs -n my-app <pod-name>
```

---

## 💡 Tips for Success

### Do's ✅
- [ ] **Practice multiple times** (muscle memory)
- [ ] **Know timings** (don't be surprised by delays)
- [ ] **Talk while demonstrating** (show your knowledge)
- [ ] **Explain each step** (not just running commands)
- [ ] **Prepare for questions** (study the Q&A section)
- [ ] **Have backup commands** (alternatives if something fails)
- [ ] **Stay calm** (technical demos sometimes fail, that's normal)

### Don'ts ❌
- [ ] Don't memorize commands (refer to docs if needed)
- [ ] Don't skip explanations (just running commands looks bad)
- [ ] Don't go into unnecessary depth (respect their time)
- [ ] Don't blame tools (take responsibility)
- [ ] Don't guess at architecture (you should know your design)
- [ ] Don't forget the "why" (anyone can run scripts)

### Interview Soft Skills

1. **Be confident**: You built this, you understand it
2. **Show enthusiasm**: This is your solution, own it
3. **Listen carefully**: Answer the question asked, not just talk
4. **Ask clarifying questions**: "Do you want me to show X or Y?"
5. **Admit unknowns**: "That's a great question, here's what I'd research"
6. **Connect to experience**: "In my previous role, I learned..."

---

## 📚 Final Preparation

### Must Know

- [x] How to start cluster
- [x] How to build image
- [x] How to deploy to K8s
- [x] What each manifest does
- [x] Why each security practice
- [x] How traffic flows
- [x] What happens on pod failure
- [x] How health checks work

### Should Know

- [x] Resource requests/limits impact
- [x] How Ingress routing works
- [x] Difference between Liveness/Readiness
- [x] Why multiple replicas matter
- [x] How Service discovers pods
- [x] Kubernetes API concepts

### Nice to Know

- [ ] Horizontal Pod Autoscaler (HPA) config
- [ ] Network Policies
- [ ] RBAC (role-based access control)
- [ ] StatefulSets vs Deployments
- [ ] CronJobs and Jobs

---

## ✨ Final Checklist (Morning Of)

- [ ] Docker running
- [ ] Minikube running or clean deleted
- [ ] Internet connection good
- [ ] Terminal(s) open and ready
- [ ] This file open for quick reference
- [ ] Cluster has fresh deployment running
- [ ] Can access app via port-forward
- [ ] K9s installed and tested
- [ ] Screenshots locations prepared
- [ ] Screenshots taken for submission

---

**Good luck! You've got this! 🚀**

Remember: The interviewer wants to see you understand:
1. **Why** you made each design choice
2. **How** the system works end-to-end
3. **What** would change for production
4. **How** you'd troubleshoot issues

Focus on clear explanations and confident demonstration.

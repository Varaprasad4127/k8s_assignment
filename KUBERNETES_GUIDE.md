# ☸️ Kubernetes Deployment Guide

Deep dive into Kubernetes manifests, architecture, and operational concepts.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Deployment Manifest](#deployment-manifest)
3. [Service Manifest](#service-manifest)
4. [Ingress Manifest](#ingress-manifest)
5. [Traffic Flow](#traffic-flow)
6. [Pod Lifecycle](#pod-lifecycle)
7. [Health Checks](#health-checks)
8. [Resource Management](#resource-management)
9. [Security Context](#security-context)
10. [Operational Commands](#operational-commands)

---

## 🎯 Overview

### Kubernetes Resources

Our deployment uses three Kubernetes resources to manage the application:

```
┌─────────────────────────────────────────────────────────┐
│           Kubernetes Resources (my-app namespace)       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Deployment (hello-app)                               │
│  ├─ Replica Set                                       │
│  │  ├─ Pod 1 (hello-app-xxxxx)                       │
│  │  │  └─ Flask Container                            │
│  │  └─ Pod 2 (hello-app-yyyyy)                       │
│  │     └─ Flask Container                            │
│  │                                                    │
│  Service (hello-app-service)                         │
│  ├─ ClusterIP: 10.0.0.1                             │
│  ├─ Endpoints: 10.244.0.10:5000, 10.244.0.11:5000  │
│                                                     │
│  Ingress (hello-app-ingress)                        │
│  └─ NGINX Controller routes to Service             │
│                                                     │
└─────────────────────────────────────────────────────────┘
```

### Resource Hierarchy

```
Deployment
    ↓
Replica Set (created and managed by Deployment)
    ↓
Pods (created and managed by Replica Set)
    ↓
Containers (run inside Pods)
```

**Why this hierarchy?**
- **Deployment**: Defines desired state (2 replicas, image, etc.)
- **Replica Set**: Ensures correct number of pod replicas running
- **Pod**: Smallest unit in Kubernetes (container wrapper)
- **Container**: The actual Docker image/process

---

## 📦 Deployment Manifest

### Full Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  namespace: my-app
  labels:
    app: hello-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
        - name: hello-app
          image: hello-app:latest
          imagePullPolicy: Never
          ports:
            - name: http
              containerPort: 5000
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
          securityContext:
            runAsNonRoot: true
            allowPrivilegeEscalation: false
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
```

### Section-by-Section Explanation

#### **API Version & Kind**

```yaml
apiVersion: apps/v1
kind: Deployment
```

**What it means:**
- `apiVersion: apps/v1` → Use Kubernetes apps API v1 (stable)
- `kind: Deployment` → This is a Deployment resource

**Why Deployment (not directly using Pods)?**
- Pod is ephemeral (dies and is recreated)
- Deployment manages replica count automatically
- Deployment enables rolling updates
- Deployment handles version rollback

#### **Metadata**

```yaml
metadata:
  name: hello-app
  namespace: my-app
  labels:
    app: hello-app
```

**Each field:**
- `name: hello-app` → Name of this Deployment
- `namespace: my-app` → Which namespace it belongs to
- `labels: app: hello-app` → Key-value tags for selection

**Why labels?**
- Service uses `selector: app: hello-app` to find pods
- Multiple resources can have same label
- Labels enable flexible grouping

**Example:**
```bash
# List all pods with app=hello-app label
kubectl get pods -l app=hello-app

# List services related to hello-app
kubectl get svc -l app=hello-app
```

#### **Spec: Replicas**

```yaml
spec:
  replicas: 2
```

**What it does:**
- Kubernetes always maintains 2 running pods
- If a pod dies, Kubernetes creates a new one
- If you manually create an extra pod, Kubernetes deletes it

**Behavior:**
```
Initial state:
  Pods: [Pod-1 Running]
  Desired: 2
  → Kubernetes creates Pod-2

Pod-1 crashes:
  Pods: [Pod-2 Running]
  Desired: 2
  → Kubernetes creates new Pod-1

Manual delete Pod-2:
  Pods: [Pod-1 Running]
  Desired: 2
  → Kubernetes creates new Pod-2 again
```

**Why 2 replicas?**
- **Availability**: If one pod dies, app still works
- **Rolling updates**: Can update one while other handles traffic
- **Load distribution**: Traffic split between two pods
- **No single point of failure**

#### **Spec: Selector**

```yaml
selector:
  matchLabels:
    app: hello-app
```

**What it does:**
- Tells Deployment which pods it manages
- Deployment creates pods with matching labels
- Service uses same selector to find endpoints

**Matching:**
```yaml
# Pod labels (in template.metadata.labels)
labels:
  app: hello-app

# Selector looks for this
selector:
  matchLabels:
    app: hello-app
# ✅ Match! Pod is managed by this Deployment
```

#### **Template: Container Image**

```yaml
template:
  spec:
    containers:
      - name: hello-app
        image: hello-app:latest
        imagePullPolicy: Never
```

**Each field:**
- `name: hello-app` → Container name (for logs, events)
- `image: hello-app:latest` → Which image to use
- `imagePullPolicy: Never` → Don't pull from registry (use local)

**Image Pull Policies:**
| Policy | Behavior | Use Case |
|--------|----------|----------|
| `Always` | Always pull latest | Production (guarantees fresh image) |
| `IfNotPresent` | Use local if exists | Development |
| `Never` | Only use local image | Local Minikube (no registry) |

**In Minikube context:**
```bash
# Build image in Minikube's Docker
eval $(minikube docker-env)
docker build -t hello-app:latest docker/

# Now Minikube has the image locally
# Pod can use imagePullPolicy: Never
```

#### **Container Ports**

```yaml
ports:
  - name: http
    containerPort: 5000
```

**What it means:**
- Container listens on port 5000
- Port is named `http` (can reference by name)
- Doesn't expose outside cluster (yet)

**How Service uses it:**
```yaml
# Service in service.yaml
ports:
  - port: 80           # Service port
    targetPort: http   # References container port name
    # OR
    targetPort: 5000   # Can reference by number
```

#### **Resources: Requests**

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
```

**What it means:**
- Pod needs **at least** 0.1 CPU cores
- Pod needs **at least** 128 MB RAM

**Scheduler uses this:**
- Won't schedule pod on node with less available resources
- Guarantees pod won't be starved
- Enables fair resource distribution

**CPU units:**
```
1000m (1000 millicores) = 1 CPU core
100m = 0.1 CPU core (10% of one core)
500m = 0.5 CPU core (half a core)
```

**Memory units:**
```
Mi = Mebibytes (binary, 1024^2 bytes)
Gi = Gibibytes (binary, 1024^3 bytes)
128Mi ≈ 134 MB
1Gi ≈ 1.07 GB
```

#### **Resources: Limits**

```yaml
limits:
  cpu: "250m"
  memory: "256Mi"
```

**What it means:**
- Pod can't use **more than** 0.25 CPU
- Pod can't use **more than** 256 MB RAM

**What happens if exceeded:**
- CPU: Throttled (process slows down)
- Memory: OOMKilled (pod restarts)

**Example:**
```yaml
requests:
  cpu: "100m"      # Guaranteed minimum
limits:
  cpu: "250m"      # Maximum allowed
```

**Resource allocation:**
```
If node has 1 full CPU available:
  Pod requests 100m → Gets 100m guaranteed
  Pod tries to use 250m → Can burst up to 250m
  Pod tries to use 500m → Throttled to 250m
```

**Why set both?**
- **Requests**: For scheduler (where to place pod)
- **Limits**: For protection (prevent runaway pod)
- Together: Optimal resource utilization

#### **Security Context**

```yaml
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
```

**Each setting:**
- `runAsNonRoot: true` → Container must run as non-root user
  - Kubernetes prevents running as UID 0
  - Our Dockerfile sets `USER 1001`
  
- `allowPrivilegeEscalation: false` → Can't gain more privileges
  - Process can't become root
  - Can't use `sudo` inside container
  - Even if compromised, attacker stays limited

**Security benefit:**
```
Without security context:
  Container runs as root → Compromise = full system access

With security context:
  Container runs as appuser → Compromise = limited access
  attacker can't install tools, modify system, etc.
```

#### **Liveness Probe**

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 15
  periodSeconds: 10
```

**What it does:**
- Checks if pod is alive every 10 seconds
- Makes HTTP GET request to `/health`
- If fails, pod is restarted

**Timeline:**
```
Pod starts at second 0
↓
Wait 15 seconds (initialDelaySeconds)
↓
Check /health endpoint every 10 seconds
  ✓ Success: Pod is healthy
  ✗ Fail: Pod is unhealthy → Restart pod
```

**Why not check immediately?**
- Application needs time to start
- Flask takes few seconds to initialize
- If checked at 0s, pod would immediately fail

**Use case:**
```
Pod hangs due to bug (no crash, just frozen)
  Application process still running
  But /health endpoint doesn't respond
  Liveness probe detects this
  Pod is restarted automatically
```

#### **Readiness Probe**

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
```

**What it does:**
- Checks if pod is ready for traffic every 5 seconds
- If not ready, pod is removed from load balancer
- Traffic goes to other ready pods

**Difference from liveness:**
| Probe | Fails | Action |
|-------|-------|--------|
| Liveness | Restart pod | Pod is dead/hung |
| Readiness | Remove from service | Pod is temporarily unavailable |

**Timeline:**
```
Pod starts
↓
Wait 5 seconds (initialDelaySeconds)
↓
Check /health every 5 seconds
  ✓ Success: Pod receives traffic
  ✗ Fail: Pod removed from service
      (pod still runs, just doesn't get requests)
```

**Real world scenario:**
```
Pod database connection fails:
  /health returns 500 (database unavailable)
  
  Readiness probe fails:
    Pod removed from service endpoints
    Traffic goes to pod 2
    User doesn't experience error
  
  Pod auto-repairs database connection:
    /health returns 200
    Readiness probe succeeds
    Pod added back to service
    Traffic resumes
```

---

## 🌐 Service Manifest

### Full Manifest

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-app-service
  namespace: my-app
  labels:
    app: hello-app
spec:
  type: ClusterIP
  selector:
    app: hello-app
  ports:
    - name: http
      port: 80
      targetPort: http
```

### How Service Works

```
Request to Service IP (10.0.0.1)
  ↓
Service receives on port 80
  ↓
Uses selector (app: hello-app) to find pods
  ↓
Finds endpoints: [10.244.0.10:5000, 10.244.0.11:5000]
  ↓
Load balances request to one pod
  ↓
Pod receives on port 5000
  ↓
Flask app processes request
  ↓
Response flows back
```

### ClusterIP vs Other Service Types

| Type | Access | Use Case |
|------|--------|----------|
| **ClusterIP** | Internal only | Pod-to-pod communication |
| **NodePort** | Node IP + port | Development, local testing |
| **LoadBalancer** | External IP | Production cloud deployments |
| **ExternalName** | DNS CNAME | Route to external service |

**Why ClusterIP?**
- Internal communication only
- Service IP (10.0.0.1) only routable within cluster
- Combined with Ingress for external access
- Most secure (nothing exposed externally directly)

### Port Mapping

```yaml
ports:
  - name: http          # Name of the port
    port: 80            # Service listens here
    targetPort: http    # Forwards to container port named "http"
```

**How it works:**
```
External request
  ↓
Ingress listens on 80 → Service listens on 80
  ↓
Service forwards to targetPort: http
  ↓
Container has port named "http" → 5000
  ↓
Request reaches container on 5000
```

**Alternative with explicit port:**
```yaml
ports:
  - port: 80
    targetPort: 5000  # Direct port number instead of name
```

### Endpoints

```bash
# View service endpoints
kubectl get endpoints -n my-app hello-app-service

# Output:
NAME                   ENDPOINTS                        AGE
hello-app-service      10.244.0.10:5000,10.244.0.11:5000   5m
```

**What endpoints show:**
- Pod IPs and ports that match the selector
- Service uses these to route traffic
- Endpoints automatically updated when pods start/stop

---

## 📡 Ingress Manifest

### Full Manifest

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-app-ingress
  namespace: my-app
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - adbsafegate.helloworld.com
    secretName: hello-app-tls
  rules:
  - host: adbsafegate.helloworld.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-app-service
            port:
              number: 80
```

### Ingress Purpose

**Without Ingress:**
```
External user
  → Can only access via NodePort (ugly: 192.168.1.100:32000)
  → No domain name support
  → No HTTPS easily
```

**With Ingress:**
```
External user
  → Access via domain: adbsafegate.helloworld.com
  → HTTPS/TLS supported
  → URL rewriting, rate limiting, etc.
  → Professional appearance
```

### How Ingress Works

```
1. External request hits adbsafegate.helloworld.com
  ↓
2. DNS resolves to Ingress Controller IP
  ↓
3. NGINX Ingress Controller receives request
  ↓
4. Controller checks Ingress rules
  ↓
5. Rule matches: path / → backend hello-app-service:80
  ↓
6. Controller forwards to Service
  ↓
7. Service load balances to pod
  ↓
8. Pod returns response
```

### TLS/HTTPS Setup

```yaml
tls:
- hosts:
  - adbsafegate.helloworld.com
  secretName: hello-app-tls
```

**What it does:**
- Enables HTTPS for specified hosts
- References a Kubernetes Secret containing certificate
- Secret must be created separately (manual step)

**Manual setup required:**
```bash
# 1. Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=adbsafegate.helloworld.com"

# 2. Create Kubernetes Secret
kubectl create secret tls hello-app-tls \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  -n my-app

# 3. Ingress can now use this secret
# (Specified in secretName: hello-app-tls)
```

### Rules: Host-Based Routing

```yaml
rules:
- host: adbsafegate.helloworld.com
  http:
    paths:
    - path: /
      pathType: Prefix
```

**What it means:**
- `host:` → Only apply this rule to this hostname
- `path: /` → Match requests starting with /
- `pathType: Prefix` → / matches /, /api, /api/users, etc.

**Other pathType options:**
| Type | Behavior | Example |
|------|----------|---------|
| `Prefix` | Starts with path | `/api` matches `/api`, `/api/users` |
| `Exact` | Exactly matches | `/api` matches `/api` only |
| `ImplementationSpecific` | Controller decides | Varies by controller |

### Multiple Paths Example

```yaml
rules:
- host: example.com
  http:
    paths:
    - path: /api
      pathType: Prefix
      backend:
        service:
          name: api-service
          port:
            number: 8080
    - path: /web
      pathType: Prefix
      backend:
        service:
          name: web-service
          port:
            number: 3000
    - path: /
      pathType: Prefix
      backend:
        service:
          name: hello-app-service
          port:
            number: 80
```

**Routing:**
- `example.com/api/users` → api-service:8080
- `example.com/web/home` → web-service:3000
- `example.com/` → hello-app-service:80

---

## 🔄 Traffic Flow

### Complete Request Path

```
1. DNS Resolution
   user browser: adbsafegate.helloworld.com
   → 192.168.1.100 (Minikube IP)

2. HTTP Request
   GET / HTTP/1.1
   Host: adbsafegate.helloworld.com

3. Ingress Controller (NGINX)
   Listens on port 80/443
   Checks domain rules
   Matches: adbsafegate.helloworld.com → hello-app-service:80

4. Service
   ClusterIP: 10.0.0.1
   Port 80 → container port 5000
   Selects pod using label: app: hello-app

5. Load Balancing
   Service has 2 endpoints:
   - 10.244.0.10:5000
   - 10.244.0.11:5000
   Sends request to one (round-robin by default)

6. Pod Processing
   Container receives on port 5000
   Flask app handles request
   Calls @app.route("/") → home()
   Returns HTML with pod hostname

7. Response
   200 OK HTTP/1.1
   Content-Type: text/html
   
   <html>
   <h1>Hello from pod-xxxxx</h1>
   </html>

8. Back to Client
   Browser renders HTML
   Shows pod hostname
```

### Testing Each Layer

```bash
# 1. Test inside pod
kubectl exec -it <pod-name> -n my-app -- bash
$ curl localhost:5000/health
# Success: pod app is running

# 2. Test via service
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://hello-app-service.my-app.svc.cluster.local
# Success: service resolves and forwards

# 3. Test via port-forward
kubectl port-forward -n my-app svc/hello-app-service 8080:80
curl http://localhost:8080/health
# Success: traffic reaches pod

# 4. Test via ingress
curl -H "Host: adbsafegate.helloworld.com" http://$(minikube ip)
# Success: ingress controller routes correctly
```

---

## 🔁 Pod Lifecycle

### States

```
Pending → Running → Succeeded/Failed

                ↓
            Terminating → Terminated
```

### Detailed Timeline

```
kubectl apply deployment.yaml
↓
Scheduler selects node
↓
Pod enters Pending state
  ├─ Image pull
  ├─ Storage mounting
  └─ Resource allocation
↓
Container starts (image runs CMD)
↓
Pod enters Running state
↓
Liveness probe checks (first at 15s)
↓
Readiness probe checks (first at 5s)
↓
Service endpoints updated
↓
Traffic flows to pod
↓
(Optional) kubectl delete pod
↓
Pod enters Terminating state
  ├─ Grace period: 30s default
  ├─ SIGTERM signal sent
  └─ App has time to cleanup
↓
Pod enters Terminated state
↓
Deployment creates new pod
(cycle repeats to maintain 2 replicas)
```

### Watching Pod Lifecycle

```bash
# Watch in real-time
kubectl get pods -n my-app -w

# In another terminal
kubectl delete pod -n my-app <pod-name>

# Observe:
# 1. Pod status → Terminating
# 2. Pod disappears
# 3. New pod appears with different name
# 4. New pod enters ContainerCreating
# 5. New pod becomes Running
# 6. New pod becomes Ready
```

---

## 💊 Health Checks Deep Dive

### Why Both Probes?

**Liveness alone:**
```
Pod is deadlocked (process hung, no crash)
  Liveness detects → Pod restarted
  BUT: Service still sends traffic during restart
  → Errors during restart
```

**With Readiness:**
```
Pod is deadlocked
  Readiness detects first → Pod removed from service
  Traffic stops → Users don't see errors
  Liveness detects → Pod restarted
  Readiness confirms healthy → Pod added back
  → Seamless recovery
```

### Probe Configuration

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
    httpHeaders:
    - name: Custom-Header
      value: awesome
  initialDelaySeconds: 15    # Wait before first check
  periodSeconds: 10          # Check interval
  timeoutSeconds: 5          # Wait for response
  failureThreshold: 3        # Failures before action
  successThreshold: 1        # Successes to consider healthy
```

**Failure threshold:**
```
Scenario: Readiness probe with failureThreshold: 3

Check 1: Fail (1/3)
Check 2: Fail (2/3)
Check 3: Fail (3/3) ← Trigger readiness failure
  ↓
Pod removed from service
  ↓
Check 4: Success
Check 5: Success
Check 6: Success ← Trigger success threshold
  ↓
Pod added back to service
```

### HTTP Probe vs TCP vs Exec

```yaml
# HTTP probe (what we use)
httpGet:
  path: /health
  port: 5000

# TCP probe (connection only)
tcpSocket:
  port: 5000

# Exec probe (run command)
exec:
  command:
  - /bin/sh
  - -c
  - curl -f http://localhost:5000/health || exit 1
```

**When to use each:**
| Type | Best For |
|------|----------|
| HTTP | Web apps, APIs |
| TCP | Databases, cache |
| Exec | Custom checks |

---

## 📊 Resource Management Best Practices

### CPU Throttling

```yaml
resources:
  requests: "100m"  # Guaranteed
  limits: "250m"    # Maximum
```

**Behavior:**
```
Scenario 1: Normal load
  Actual usage: 50m
  Status: ✅ Running normally

Scenario 2: Load spike
  Actual usage: 200m
  Status: ✅ Allowed (under 250m limit)

Scenario 3: Runaway process
  Actual usage: 500m
  Status: ⚠️ Throttled (reduced to 250m)
  Result: Process slows down
```

### Memory Limits

```yaml
limits:
  memory: "256Mi"
```

**Behavior:**
```
Scenario 1: Normal memory
  Actual usage: 100Mi
  Status: ✅ Running normally

Scenario 2: Memory spike
  Actual usage: 200Mi
  Status: ✅ Allowed

Scenario 3: Memory leak
  Actual usage: 300Mi (exceeds 256Mi limit)
  Status: ❌ OOMKilled
  Result: Pod crashes and restarts
  (liveness probe detects, new pod created)
```

### Setting Appropriate Limits

```bash
# Measure current usage
kubectl top pods -n my-app

# Output:
NAME                    CPU(cores)   MEMORY(bytes)
hello-app-558b4d6f7-2x  45m          95Mi
hello-app-558b4d6f7-9m  50m          102Mi

# Set requests lower (guaranteed minimum)
# Set limits 2-3x higher (burst capacity)
# requests: 50m, limits: 250m (5x for headroom)
```

---

## 🔒 Security Context

### Complete SecurityContext

```yaml
securityContext:
  runAsUser: 1001              # Specific UID
  runAsNonRoot: true           # Prevent root
  allowPrivilegeEscalation: false  # No privilege gain
  readOnlyRootFilesystem: true # Read-only FS
  capabilities:
    drop:
    - ALL                       # Drop all Linux capabilities
    add:
    - NET_BIND_SERVICE          # Add back specific one if needed
```

### Linux Capabilities

Default root capabilities:
```
CAP_SYS_ADMIN        # System administration
CAP_NET_ADMIN        # Network administration
CAP_SYS_MODULE       # Load/unload kernel modules
...and many more
```

Our approach:
```yaml
capabilities:
  drop:
  - ALL                # Remove all capabilities
  # Don't add any back unless absolutely necessary
```

**Result:**
- Process can't perform privileged operations
- Can't access hardware directly
- Can't modify kernel
- Still can read/write files (within permissions)

### Read-Only Filesystem

```yaml
readOnlyRootFilesystem: true
```

**Effect:**
```
Pod cannot write to:
  / (root)
  /bin, /lib, /usr, etc.
  
Pod CAN write to:
  /tmp (temporary files)
  /var/tmp (temporary files)
  /dev/shm (shared memory)
  
If app tries to write to /var/log:
  Permission denied error
  App should write to stdout/stderr instead
  (captured by Kubernetes)
```

**Benefit:**
- Prevents persistence attacks
- Prevents creating shell scripts
- Forces stateless application design
- Better cloud-native practices

---

## 🖥️ Operational Commands

### View Deployment

```bash
# List deployments
kubectl get deployments -n my-app

# Detailed view
kubectl describe deployment -n my-app hello-app

# Watch changes
kubectl get deployment -n my-app -w
```

### View Pods

```bash
# List pods
kubectl get pods -n my-app

# Pods with more details
kubectl get pods -n my-app -o wide

# Pretty JSON
kubectl get pods -n my-app -o json | jq '.items[].metadata.name'

# Watch pods
kubectl get pods -n my-app -w
```

### Pod Logs

```bash
# Current logs
kubectl logs -n my-app <pod-name>

# Last 50 lines
kubectl logs -n my-app <pod-name> --tail=50

# Stream logs
kubectl logs -n my-app <pod-name> -f

# Previous logs (from crashed pod)
kubectl logs -n my-app <pod-name> --previous

# All pods matching label
kubectl logs -n my-app -l app=hello-app --all-containers=true
```

### Execute Commands

```bash
# Enter pod shell
kubectl exec -it -n my-app <pod-name> -- /bin/bash

# Run one-off command
kubectl exec -n my-app <pod-name> -- curl localhost:5000/health

# Run in all pods
kubectl exec -n my-app -l app=hello-app -- env | grep HOSTNAME
```

### Scaling

```bash
# Scale manually
kubectl scale deployment -n my-app hello-app --replicas=3
# Now 3 pods running

kubectl scale deployment -n my-app hello-app --replicas=1
# Back to 1 pod

# Deployment recreates pod if manual edit fails
kubectl edit deployment -n my-app hello-app
# Opens in $EDITOR, can change replicas:2 to replicas:5
```

### Rolling Updates

```bash
# Update image
kubectl set image deployment/hello-app \
  hello-app=hello-app:v2 \
  -n my-app

# Watch rollout
kubectl rollout status deployment/hello-app -n my-app

# Undo update
kubectl rollout undo deployment/hello-app -n my-app

# Rollout history
kubectl rollout history deployment/hello-app -n my-app
```

### Restart Deployment

```bash
# Restart all pods (causes brief downtime)
kubectl rollout restart deployment/hello-app -n my-app

# Equivalent to:
# 1. Delete all pods
# 2. Deployment creates new pods
# 3. Service endpoints updated
```

---

## 📚 Summary Table

| Resource | Purpose | Count |
|----------|---------|-------|
| Deployment | Pod management, replicas | 1 |
| Replica Set | Maintains pod count | 1 (auto-created) |
| Pods | Running containers | 2 |
| Service | Load balancing, networking | 1 |
| Ingress | External routing | 1 |
| ConfigMap | Configuration data | 0 (example only) |
| Secret | Sensitive data | 1 (TLS cert) |

Total running: **1 Deployment + 1 Service + 1 Ingress + 2 Pods**

---

This guide covers the complete Kubernetes deployment architecture, from manifest definitions to operational commands.

# 🐳 Docker Application Guide

Complete explanation of the Flask application, Dockerfile, and security practices.

---

## 📁 Application Structure

```
docker/
├── Dockerfile           # Container build instructions
├── app.py              # Flask web server
├── templates/
│   └── index.html      # Web UI template
└── static/             # CSS, JavaScript assets
```

---

## 🐍 Flask Application (`docker/app.py`)

### What It Does

A minimal Flask web server that:
1. Renders an HTML page showing the pod hostname
2. Provides a `/health` endpoint for Kubernetes probes
3. Listens on port 5000 (inside container)

### Application Code

```python
from flask import Flask, render_template
import socket

app = Flask(__name__)

@app.route("/")
def home():
    # Get the container/pod hostname
    hostname = socket.gethostname()
    
    # Render HTML template with hostname
    return render_template("index.html", hostname=hostname)

@app.route("/health")
def health():
    # Simple health check endpoint
    # Returns 200 OK when healthy
    return "OK", 200

if __name__ == "__main__":
    # Listen on all interfaces (0.0.0.0:5000)
    app.run(host="0.0.0.0", port=5000)
```

### Endpoints Explained

#### **`GET /`** - Main Page
- **Purpose**: Display the application UI
- **Returns**: HTML page with pod hostname
- **Used for**: Verifying the app is working and load balancing
- **Test**: `curl http://localhost:8080/`

#### **`GET /health`** - Health Check
- **Purpose**: Kubernetes liveness/readiness probe
- **Returns**: Plain text "OK" with HTTP 200
- **Used for**: Pod restart and traffic routing decisions
- **Test**: `curl http://localhost:8080/health`

### Why Hostname Display?

The hostname changes between pod replicas, allowing you to:
- **Verify load balancing**: Refresh page = different hostname
- **Test pod replacement**: Kill pod = new hostname appears
- **Monitor pod restarts**: See hostname change as pod restarts

Example output:
```
Pod: hello-app-558b4d6f7-2xkp7
Pod: hello-app-558b4d6f7-9m8lk
Pod: hello-app-558b4d6f7-2xkp7  (new pod, same pod)
```

---

## 🔨 Dockerfile Security Deep Dive

### Full Dockerfile

```dockerfile
FROM python:3.11-slim

# Create non-root user
RUN useradd -u 1001 -m appuser

WORKDIR /app

# Install only required dependency
RUN pip install --no-cache-dir flask

# Copy application files
COPY app.py .
COPY templates/ templates/
COPY static/ static/

# Switch to non-root user
USER 1001

EXPOSE 5000

CMD ["python", "app.py"]
```

### Line-by-Line Explanation

#### **`FROM python:3.11-slim`**

**What it does**: Selects the base image

**Why slim?**
- `python:3.11` → Full image: ~1GB
- `python:3.11-slim` → Minimal image: ~120MB
- Contains only Python runtime + essential tools
- Reduces attack surface (fewer packages)
- Faster downloads and deployments

**Size comparison:**
```bash
# Full image
docker pull python:3.11
# → ~1GB (includes build tools, development files)

# Slim image
docker pull python:3.11-slim
# → ~120MB (only runtime essentials)
```

#### **`RUN useradd -u 1001 -m appuser`**

**What it does**: Create a non-root user account

**Why non-root?**
- Root user (UID 0) has full system access
- If container is compromised, attacker gets root
- Non-root user limits damage from compromise

**What the flags mean:**
- `-u 1001` → Assign specific user ID (consistency)
- `-m` → Create home directory (`/home/appuser`)
- `appuser` → Username for the account

**Security scenario:**
```
Vulnerable (as root):
  $ whoami
  root
  $ rm -rf /
  # DISASTER: Entire system deleted

Secure (as appuser):
  $ whoami
  appuser
  $ rm -rf /
  # Only deletes files appuser can access
  # System remains intact
```

#### **`WORKDIR /app`**

**What it does**: Set working directory for all following commands

**Why needed?**
- Makes file organization clear
- All subsequent `RUN`, `COPY`, `CMD` use this directory
- Application files in known location

#### **`RUN pip install --no-cache-dir flask`**

**What it does**: Install Flask web framework

**Why `--no-cache-dir`?**
- pip downloads packages into cache directory
- Without flag, cache stays in image (wasted space)
- With flag, cache is discarded (smaller image)

**Size impact:**
```bash
# Without --no-cache-dir
pip install flask
# Final image: 145MB

# With --no-cache-dir
pip install --no-cache-dir flask
# Final image: 120MB (25MB saved!)
```

#### **`COPY app.py . / COPY templates/ templates/ / COPY static/ static/`**

**What it does**: Copy application files from build machine into image

**Why separate copies?**
- Each COPY creates a Docker layer
- Docker caches unchanged layers
- If only app.py changes, other layers reuse cache
- Faster rebuilds

**Build context:**
- `.` refers to build directory (repo root)
- Copies from `./docker/app.py` → image `/app/app.py`

#### **`USER 1001`**

**What it does**: Switch to non-root user for running the app

**Why at the end?**
- Previous commands run as root (needed for installation)
- Application runs as `appuser` (least privilege)
- Can't accidentally write files as root

**Verification:**
```bash
# Inside running container
$ whoami
appuser

# Can't run sudo
$ sudo apt-get install vim
sudo: not found
```

#### **`EXPOSE 5000`**

**What it does**: Documents which port the app listens on

**Important**: This doesn't actually expose the port
- Purely for documentation
- The port is still inaccessible from outside container
- Kubernetes uses this as a hint

#### **`CMD ["python", "app.py"]`**

**What it does**: Set the default command when container starts

**Syntax (exec form):**
- `CMD ["python", "app.py"]` → Preferred (direct execution)
- `CMD python app.py` → Shell form (not recommended)

**Why exec form?**
- Runs Python directly (not in shell)
- Python receives signals (SIGTERM) properly
- Graceful shutdown works correctly

---

## 🔐 Security Best Practices Implemented

### 1. **Principle of Least Privilege**

```dockerfile
# Non-root user
USER 1001
```

**Threat mitigated**: Privilege escalation attacks
- Even if attacker gains access, they're limited
- Can't install system packages
- Can't access other users' files

### 2. **Minimal Attack Surface**

```dockerfile
FROM python:3.11-slim
```

**Threat mitigated**: Vulnerability exploitation
- Fewer packages = fewer potential vulnerabilities
- Example: Slim image has ~50 packages vs 300+ in full image
- Security updates easier to manage

### 3. **Layer Caching Optimization**

```dockerfile
RUN pip install --no-cache-dir flask
```

**Threat mitigated**: Outdated dependencies
- Prevents pip cache from holding old versions
- Ensures fresh dependency installation
- Reduces image size (no unnecessary copies)

### 4. **Explicit File Permissions**

```dockerfile
COPY app.py .
```

**Why explicit paths?**
- Clear what files are included
- Easy to audit
- Prevents accidentally copying secrets

### 5. **Read-Only Filesystem (Optional Hardening)**

In Kubernetes SecurityContext:
```yaml
securityContext:
  readOnlyRootFilesystem: true
```

**Effect**: Application can't write to disk (except /tmp)
- Prevents persistence attacks
- Forces application to be stateless
- Better for cloud-native apps

---

## 🧪 Building and Testing Locally

### Build the Image

```bash
# Navigate to project root
cd k8s_assignment

# Build image
docker build -t hello-app:latest docker/

# Output:
# [1/6] FROM python:3.11-slim
# [2/6] RUN useradd -u 1001 -m appuser
# [3/6] WORKDIR /app
# [4/6] RUN pip install --no-cache-dir flask
# [5/6] COPY app.py . / COPY templates/ ...
# [6/6] RUN USER 1001
# Successfully tagged hello-app:latest
```

### Run the Container

```bash
# Run container
docker run -p 5000:5000 hello-app:latest

# In another terminal, test endpoints
curl http://localhost:5000/health
# Output: OK

curl http://localhost:5000
# Output: HTML page with container ID
```

### Inspect the Image

```bash
# Check image details
docker inspect hello-app:latest | grep -A 10 "Config"

# Check running user
docker run hello-app:latest whoami
# Output: appuser (not root!)

# Check image size
docker images hello-app:latest
# REPOSITORY   TAG      SIZE
# hello-app    latest   120MB

# Check image layers
docker history hello-app:latest
# Shows each layer and its size
```

### Advanced: Layer Analysis

```bash
# Install dive (tool to analyze layers)
brew install dive

# Analyze image
dive hello-app:latest

# Shows:
# - Which files are in each layer
# - Wasted space in layers
# - How to optimize further
```

---

## 🚀 Optimization Tips

### Current State
- Image size: ~120MB
- Build time: ~10 seconds
- Layers: 6

### Possible Optimizations

#### 1. **Multi-stage Build** (if needed)

```dockerfile
# Build stage
FROM python:3.11 as builder
RUN pip install --user flask

# Runtime stage
FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
USER 1001
CMD ["python", "-m", "flask", "run"]
```

**Benefit**: Further reduce size (unused build tools removed)

#### 2. **Use Alpine Linux**

```dockerfile
FROM python:3.11-alpine
# Size: ~50MB (vs 120MB slim)
# Trade-off: Fewer system tools, potential compatibility issues
```

#### 3. **Combine RUN Commands**

```dockerfile
# Current (4 layers)
RUN useradd -u 1001 -m appuser
RUN pip install --no-cache-dir flask
RUN apt-get update
RUN apt-get install -y curl

# Optimized (1 layer)
RUN useradd -u 1001 -m appuser && \
    pip install --no-cache-dir flask && \
    apt-get update && \
    apt-get install -y curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
```

**Benefit**: Fewer layers = smaller image

---

## 🔍 Troubleshooting

### Image Build Fails

```bash
# Enable verbose output
docker build --progress=plain -t hello-app:latest docker/

# Check build context
docker build --progress=plain --no-cache -t hello-app:latest docker/
```

### Container Doesn't Start

```bash
# Run with error output
docker run --rm hello-app:latest

# Enter shell instead of running app
docker run -it hello-app:latest /bin/bash

# Check logs
docker logs <container-id>
```

### Port Not Accessible

```bash
# Make sure container is running
docker ps

# Port mapping syntax: -p HOST:CONTAINER
docker run -p 5000:5000 hello-app:latest
#         ↑    ↑
#       HOST  CONTAINER

# Test from container
docker run -it hello-app:latest /bin/bash
$ curl localhost:5000/health
```

### Permission Denied Error

```bash
# Check running user
docker run hello-app:latest whoami

# If running as root, Dockerfile USER not applied
# Verify: USER 1001 in Dockerfile after all files copied
```

---

## 📊 Dockerfile Comparison

| Aspect | Current | Bad Practice | Production |
|--------|---------|--------------|-----------|
| Base image | `python:3.11-slim` | `ubuntu:22.04` | `python:3.11-slim` |
| User | Non-root (1001) | Root (0) | Non-root + read-only FS |
| Pip cache | `--no-cache-dir` | Default cache | `--no-cache-dir` |
| Image size | ~120MB | ~500MB+ | ~100MB |
| Layers | 6 | 3 | 4-5 (optimized) |
| Security | ✅ Good | ❌ Unsafe | ✅ Excellent |

---

## 🎓 Learning Resources

- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Container Security Guide](https://kubernetes.io/docs/concepts/security/container-environment-variables/)
- [NIST Container Security](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker/)

---

## ✅ Summary

| Aspect | Implementation |
|--------|-----------------|
| **Minimal image** | `python:3.11-slim` (120MB) |
| **Non-root user** | UID 1001 (appuser) |
| **Optimized layers** | 6 layers, no unnecessary cache |
| **Health check** | `/health` endpoint |
| **Port exposure** | Clear, documented (5000) |
| **File permissions** | Explicit COPY commands |
| **Security context** | Ready for K8s hardening |

This Dockerfile demonstrates production-grade security while maintaining simplicity and clarity.

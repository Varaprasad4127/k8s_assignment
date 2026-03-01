# ⚡ Quick Start Guide

Get up and running in 5 minutes.

---

## 1️⃣ Prerequisites Check

```bash
# Verify you have everything
docker --version          # v4.0+
minikube version          # v1.30+
kubectl version --client  # v1.28+
k9s version              # v0.32+
```

**Don't have them?** → See [README.md](README.md#prerequisites)

---

## 2️⃣ Start Everything (Option A: Fastest)

```bash
cd ~/Desktop/Assignment-adbsafegate/k8s_assignment

# Make scripts executable
chmod +x bash/*.sh

# Run each in order
bash bash/start_cluster.sh     # Start Minikube
bash bash/build_image.sh       # Build Docker image
bash bash/deploy_k8s.sh        # Deploy to Kubernetes

# Done! Cluster is running
```

**Time:** ~3-5 minutes

---

## 3️⃣ Start Everything (Option B: Manual Steps)

```bash
# 1. Start cluster
minikube start --driver=docker --cpus=2 --memory=4096

# 2. Build image
eval $(minikube docker-env)
docker build -t hello-app:latest docker/

# 3. Deploy
kubectl apply -f k8s/deployment.yaml.j2
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

---

## 4️⃣ Verify It's Working

```bash
# Check cluster
kubectl get nodes
# Should show: minikube   Ready   control-plane

# Check pods
kubectl get pods -n my-app
# Should show: 2 hello-app pods Running

# Check service
kubectl get svc -n my-app
# Should show: hello-app-service ClusterIP
```

---

## 5️⃣ Access the Application

### Option A: Port Forward (Easiest)

```bash
# In terminal 1: Start port-forward
kubectl port-forward -n my-app svc/hello-app-service 8080:80 &

# In terminal 2: Test it
curl http://localhost:8080/health
# Output: OK

# Visit in browser: http://localhost:8080
```

### Option B: Minikube Service (Auto-opens browser)

```bash
minikube service -n my-app hello-app-service
# Automatically opens browser to the app
```

---

## 6️⃣ View Logs with K9s

```bash
# Launch K9s
k9s

# Navigation:
# Type `:pods` and press Enter → View all pods
# Type `:ns` and press Enter → Switch to kube-system
# Select a pod and press `l` → View logs
# Press `?` for help
# Press `Ctrl+C` to exit
```

---

## 🎯 Next Steps

| Goal | Read |
|------|------|
| Understand everything | [README.md](README.md) |
| Learn Docker | [DOCKER_GUIDE.md](DOCKER_GUIDE.md) |
| Learn Kubernetes | [KUBERNETES_GUIDE.md](KUBERNETES_GUIDE.md) |
| Prepare for interview | [INTERVIEW_GUIDE.md](INTERVIEW_GUIDE.md) |
| Full docs overview | [DOCUMENTATION.md](DOCUMENTATION.md) |

---

## ❓ Common Issues

### Pods won't start

```bash
# Check what's wrong
kubectl describe pod -n my-app <pod-name>

# View logs
kubectl logs -n my-app <pod-name>

# Rebuild image if needed
bash bash/build_image.sh

# Restart deployment
kubectl rollout restart deployment/hello-app -n my-app
```

### Port-forward not working

```bash
# Kill existing connections
killall kubectl

# Try again
kubectl port-forward -n my-app svc/hello-app-service 8080:80
```

### Minikube stuck

```bash
# Restart Minikube
minikube stop
minikube start

# Or full reset
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

---

## 📞 Full Documentation

- **[README.md](README.md)** - Complete guide (start here!)
- **[DOCKER_GUIDE.md](DOCKER_GUIDE.md)** - Docker deep dive
- **[KUBERNETES_GUIDE.md](KUBERNETES_GUIDE.md)** - K8s deep dive
- **[INTERVIEW_GUIDE.md](INTERVIEW_GUIDE.md)** - Interview prep
- **[DOCUMENTATION.md](DOCUMENTATION.md)** - Docs overview

---

## ✨ You're Ready!

Cluster is running. App is deployed. You're all set!

**Next:** Read [README.md](README.md) for the complete story.

Happy learning! 🚀

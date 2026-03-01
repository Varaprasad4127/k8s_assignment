# Runbook: Deploy & Access (GitHub → EC2 → Minikube → App)

Purpose: concise, interview-ready runbook describing the exact demo steps to deploy the system from GitHub, verify it from inside the EC2 instance, and access the app locally.

---

## Quick Architecture Summary
- GitHub Actions (Terraform) provisions an EC2 instance and runs `user-data` to install Docker/kubectl/minikube/Ansible and register a self-hosted GitHub runner on the EC2.
- GitHub Actions (Ansible workflows) run on that self-hosted runner and perform the Minikube + Docker + K8s resource deployments.
- Access paths:
  - From EC2: use `kubectl` / `minikube` directly.
  - From local machine: use SSH port-forwarding to access Minikube services/dashboards and map the ingress host to `127.0.0.1`.

---

## Prerequisites (on your laptop)
- SSH private key matching the public key supplied to Terraform (`TF_PUBLIC_KEY`).
- GitHub repo configured with required secrets (AWS credentials, TF public key, GitHub token in Secrets Manager).
- Local `ssh` and `kubectl` installed for port-forwarding and verification.

---

## High-level Run Steps
1. Trigger GitHub Terraform workflow (creates EC2 and runs `user-data`).
2. Wait for userdata to finish; obtain EC2 public IP.
3. SSH into the EC2 instance from your laptop.
4. Trigger Ansible Minikube workflow (starts Minikube on EC2) or run it locally on EC2.
5. Verify Minikube & start dashboard; set up local forwarding.
6. Trigger Ansible Docker role to build the image inside Minikube's Docker env.
7. Trigger Ansible deployment → service → ingress roles, verifying after each.
8. Map ingress hostname to `127.0.0.1` and access app from your local browser.
9. Trigger monitoring, port-forward Grafana; then deploy HPA and run load test to verify autoscaling.

---

## Detailed Run Steps (commands & checks)

### 1) Trigger Terraform (GitHub Actions)
- In GitHub → Actions → run **`Terraform Apply`**.
- Expected: EC2 is created; `user-data` runs and prepares the instance.

What `user-data` does (summary): installs Docker, kubectl, Minikube, Ansible, clones repo and registers a self-hosted GitHub Actions runner on the EC2 instance.

---

### 2) Wait for userdata completion and get EC2 IP
- Wait ~3–10 minutes for `user-data` to complete.
- In AWS Console → EC2 → find instance and copy the **Public IP**.

Optional: Terraform workflow logs may print the public IP as output.

---

### 3) SSH to EC2 (from your laptop)

```bash
ssh -i ~/.ssh/<your-key>.pem ubuntu@<EC2_PUBLIC_IP>
```

Quick checks on EC2:
```bash
docker --version
kubectl version --client
minikube version
ansible --version
ps aux | grep actions-runner
```
Expected: versions show, and the actions-runner process is running.

---

### 4) Run Minikube role (prefer via GitHub self-hosted runner)
Preferred: trigger the Ansible Minikube workflow in GitHub so the self-hosted runner on EC2 executes it.

Manual on EC2 (if preferred):
```bash
cd ~/k8s_assignment/ansible
ansible-playbook main.yml --tags minikube
```

Verify:
```bash
minikube status
kubectl get nodes
```
Expected: `minikube` Ready.

---

### 5) Build Docker image in Minikube Docker env (docker role)
Trigger (recommended via GitHub Ansible workflow):
```bash
ansible-playbook main.yml --tags docker
```

Verify on EC2 (inside Minikube Docker env):
```bash
eval $(minikube docker-env)
docker images | grep hello-app
```
Expected: `hello-app:${COMMIT_SHA}` and `hello-app:latest` exist.

---

### 6) View Minikube dashboard and port-forward to local
Get dashboard URL (or start it):
```bash
minikube dashboard --url &
```
If it prints `http://<MINIKUBE_IP>:<PORT>`, forward that port locally:

```bash
# From local laptop
ssh -i ~/.ssh/<your-key>.pem -L 30000:<MINIKUBE_IP>:<DASHBOARD_PORT> ubuntu@<EC2_PUBLIC_IP>
# open http://localhost:30000 in the browser
```
Or, on EC2 run `kubectl port-forward` for the dashboard and tunnel the same port.

---

### 7) Run deployment role and verify
```bash
ansible-playbook main.yml --tags deployment
```
Check:
```bash
kubectl get deployment -n my-app
kubectl get pods -n my-app
```
Expected: `hello-app` deployment present with 2 Running pods.

---

### 8) Run service role and verify
```bash
ansible-playbook main.yml --tags service
kubectl get svc -n my-app
kubectl describe svc hello-app-service -n my-app
```
Expected: ClusterIP present, mapping 80→5000.

---

### 9) Run ingress role and verify access
```bash
ansible-playbook main.yml --tags ingress
kubectl get ingress -n my-app
```
Find Minikube IP and ingress listening port:
```bash
minikube ip
kubectl get svc -n ingress-nginx
```
Forward ingress to local:
```bash
ssh -i ~/.ssh/<key>.pem -L 8080:<MINIKUBE_IP>:80 ubuntu@<EC2_PUBLIC_IP>
# open http://localhost:8080
```

---

### 10) Map ingress hostname to localhost
Edit local `/etc/hosts` to map domain to localhost (requires sudo):

```bash
sudo -- sh -c 'echo "127.0.0.1 adbsafegate.helloworld.com" >> /etc/hosts'
```
Now open `https://adbsafegate.helloworld.com` in your browser (or http accordingly).

---

### 11) Deploy monitoring role and access Grafana
```bash
ansible-playbook main.yml --tags monitoring
kubectl port-forward -n monitoring svc/grafana 3000:80 &
# open http://localhost:3000 (admin/prom-operator)
```

---

### 12) Deploy HPA and run load test
```bash
ansible-playbook main.yml --tags hpa
kubectl get hpa -n my-app
```
Start a simple load from local (after port-forwarding the service):
```bash
for i in {1..200}; do curl -s http://localhost:8080/ > /dev/null & done
```
Verify HPA scaling:
```bash
kubectl get hpa -n my-app -w
kubectl get pods -n my-app
```

---

## Quick Troubleshooting
- `minikube status` not `Running` → `minikube logs`.
- Pod fail: `kubectl describe pod -n my-app <pod>` and `kubectl logs -n my-app <pod>`.
- Missing Docker image: ensure `eval $(minikube docker-env)` was executed before `docker images`.
- Runner not picking jobs: check runner logs under `/home/ubuntu/actions-runner/_diag`.
- Port-forward issues: ensure tunnel and `kubectl port-forward` are running and ports match.

---

## Demo Checklist (one-liner readout)
- Run `Terraform Apply` → Wait for userdata → SSH to EC2
- Run Minikube role → Verify cluster
- Run Docker role → Verify image
- Run Deployment → Service → Ingress (verify each)
- Port-forward + update `/etc/hosts` → Open app locally
- Run Monitoring → Grafana → HPA → load test

---

If you want, I can also produce a printable checklist, a 1-page slide script, or export a PNG of the architecture diagram for your slides.

**File added**: `RUNBOOK.md`

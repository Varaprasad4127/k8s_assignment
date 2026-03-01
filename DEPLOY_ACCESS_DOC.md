# Deploy & Access Guide (GitHub → EC2 → Minikube → App)

Purpose: a concise, interview-friendly step-by-step guide that shows how you deploy this project from GitHub and how to access the application both from inside the EC2 and from your local machine.

Keep this at-hand during the demo: follow each numbered step and verify the expected outputs.

---

## Quick Architecture Summary
- GitHub Actions (Terraform) provisions an EC2 instance and runs `user-data` to install Docker/kubectl/minikube/Ansible and register a self-hosted GitHub runner on the EC2.
- GitHub Actions (Ansible workflows) run on that self-hosted runner (on EC2) and perform the Minikube + Docker + K8s resource deployments.
- Access paths:
  - From EC2: use `kubectl` / `minikube` directly.
  - From local machine: use SSH port-forwarding to access Minikube services / dashboards, and map the ingress host to `127.0.0.1` in `/etc/hosts` for browser access.

---

## Prerequisites (on your laptop)
- `ssh` configured and the private key (the public key was provided to Terraform via `TF_PUBLIC_KEY`).
- GitHub repo configured with required secrets (AWS credentials, TF public key, etc.).
- `kubectl` and `ssh` installed locally for verification and port forwarding.

---

## Demo Steps (high level)
1. Run GitHub Terraform workflow to create EC2 and run `user-data`.
2. Wait for userdata to finish (health checks); get EC2 public IP.
3. SSH into EC2 from your local machine.
4. Run Ansible Minikube workflow (starts Minikube on EC2).
5. Verify Minikube from EC2.
6. Run Ansible Docker role (build image inside Minikube Docker env).
7. Verify Docker image on EC2 (inside Minikube env).
8. Start port-forwarding to Minikube dashboard and open locally.
9. Run Ansible deployment/service/ingress roles and verify each.
10. Set up local forwarding and `/etc/hosts` mapping for ingress host → 127.0.0.1.
11. Access application locally in browser.
12. Run monitoring and HPA roles; perform load test and verify autoscaling.

---

## Full Step-by-step Procedure (with commands and checks)

### 1) Trigger Terraform (GitHub)
- In GitHub → Actions → choose **`Terraform Apply`** workflow → Run.
- Expected result: EC2 instance created and `user-data` runs on instance startup.

What `user-data` does (high level): installs Docker, kubectl, minikube, Ansible, clones repo and registers a self-hosted GitHub Actions runner on the instance.

---

### 2) Wait for userdata and get EC2 IP
- Wait ~3–10 minutes for userdata to finish.
- In AWS Console -> EC2 -> find the instance and note the **Public IP**.

Optional quick check from GitHub Actions logs: the Terraform workflow usually prints instance details and (if configured) outputs the public IP.

---

### 3) SSH into EC2 from your local laptop

```bash
ssh -i ~/.ssh/<your-key>.pem ubuntu@<EC2_PUBLIC_IP>
```

Quick checks on EC2:
```bash
# Docker
docker --version
# kubectl & minikube
kubectl version --client
minikube version
# Ansible
ansible --version
# Verify GitHub runner process
ps aux | grep actions-runner
```
Expected: each command returns a valid version or a running process for the runner.

---

### 4) Start Minikube via Ansible (from GitHub Actions or locally on EC2)
Preferred approach: run the Ansible Minikube workflow from GitHub so the self-hosted runner executes it on EC2.

If running manually on EC2:
```bash
cd ~/k8s_assignment/ansible
ansible-playbook main.yml --tags minikube
```

Verify (on EC2):
```bash
minikube status
kubectl get nodes
```
Expected: Minikube shows `Running` and `kubectl get nodes` lists `minikube` as Ready.

---

### 5) Build Docker image inside Minikube Docker environment (docker role)
Run the Ansible docker role (via GitHub Actions running on EC2 or locally on EC2):
```bash
# via Ansible tags (run the docker role)
ansible-playbook main.yml --tags docker
```

What it does (typical tasks):
- `eval $(minikube docker-env)` -- point Docker CLI to Minikube's Docker daemon
- `docker build -t hello-app:${COMMIT_SHA} docker/`
- `docker tag hello-app:${COMMIT_SHA} hello-app:latest`

Verify on EC2 (inside minikube docker-env):
```bash
# ensure env
eval $(minikube docker-env)
docker images | grep hello-app
```
Expected: image(s) `hello-app:${COMMIT_SHA}` and `hello-app:latest` present.

---

### 6) Open Minikube Dashboard & check its port
Start the dashboard (on EC2) or use the Ansible role output which shows the dashboard URL.

Common commands (on EC2):
```bash
minikube dashboard --url &
# or get the dashboard URL printed
```
This prints a URL like `http://192.168.x.y:xxxxx`.

To access the dashboard locally, set up an SSH tunnel or port forward from your laptop:

```bash
# From your local machine
ssh -i ~/.ssh/<your-key>.pem -L 30000:<MINIKUBE_IP>:<DASHBOARD_PORT> ubuntu@<EC2_PUBLIC_IP>
# Then open http://localhost:30000 in your browser
```
Or, port-forward using kubectl (run on EC2 and tunnel the same port):
```bash
# on EC2
kubectl port-forward -n kube-system svc/kubernetes-dashboard 30000:80 &
# on local: ssh tunnel as above if needed
```
Expected: Dashboard accessible in browser at `http://localhost:30000`.

---

### 7) Run Deployment role (create K8s deployment)
Run the Ansible deployment role via GitHub (self-hosted runner) or locally on EC2:
```bash
ansible-playbook main.yml --tags deployment
```

Verify (on EC2):
```bash
kubectl get namespace my-app || true
kubectl get deployment -n my-app
kubectl get pods -n my-app
```
Expected: Deployment `hello-app` created with 2 pods in `Running` state.

Verify in dashboard: you should see the two pods under `my-app` namespace.

---

### 8) Run Service role (ClusterIP)
```bash
ansible-playbook main.yml --tags service
```
Verify:
```bash
kubectl get svc -n my-app
kubectl describe svc hello-app-service -n my-app
```
Expected: `hello-app-service` present, port mapping 80→5000.

---

### 9) Run Ingress role and verify
```bash
ansible-playbook main.yml --tags ingress
```
Verify In EC2:
```bash
kubectl get ingress -n my-app
kubectl get svc -n ingress-nginx # or check the ingress controller namespace
```
Find:
- Minikube IP: `minikube ip`
- Ingress service port (or NodePort if configured): `kubectl get svc -n ingress-nginx`

Set up port forwarding from your laptop to ingress (example):
```bash
# If ingress listens on port 80 on the Minikube node, forward that port
ssh -i ~/.ssh/<key>.pem -L 8080:<MINIKUBE_IP>:80 ubuntu@<EC2_PUBLIC_IP>
# visit http://localhost:8080
```

Alternatively, forward the ingress controller service port via kubectl port-forward (run on EC2) and tunnel it to your laptop.

---

### 10) Map ingress host to localhost (/etc/hosts)
Once you've forwarded the ingress HTTP/HTTPS ports to `localhost`, edit your local `/etc/hosts` and map the application domain used in the ingress to `127.0.0.1`:

```bash
# On your local laptop (needs sudo)
sudo -- sh -c 'echo "127.0.0.1 adbsafegate.helloworld.com" >> /etc/hosts'
```
Then open `https://adbsafegate.helloworld.com` (or http depending on TLS) in your local browser.

---

### 11) Deploy Monitoring role and access Grafana
```bash
ansible-playbook main.yml --tags monitoring
```
Verify Grafana service and forward to local port:
```bash
kubectl get svc -n monitoring
kubectl port-forward -n monitoring svc/grafana 3000:80 &
# open http://localhost:3000 (admin / prom-operator or as configured)
```

---

### 12) Deploy HPA and run load test
```bash
ansible-playbook main.yml --tags hpa
kubectl get hpa -n my-app
```
Load test (from your laptop or EC2):
```bash
# simple loop (not sophisticated load testing)
for i in {1..200}; do curl -s http://localhost:8080/ > /dev/null & done

# or use `hey` or `ab` if installed:
# hey -z 30s -c 50 http://localhost:8080/
```
Verify HPA scales:
```bash
kubectl get hpa -n my-app -w
kubectl get pods -n my-app
```
Expected: replicas increase above 2 when CPU target exceeded.

---

## Checks & Troubleshooting (quick)
- If `minikube status` is not `Running`, check `minikube logs`.
- If pods fail to start: `kubectl describe pod -n my-app <pod>` and `kubectl logs -n my-app <pod>`.
- Docker image missing: ensure `eval $(minikube docker-env)` was executed before `docker images`.
- If GitHub runner isn't picking up jobs: check runner logs (`ps aux | grep runner`) and /home/ubuntu/actions-runner/_diag for errors.
- Port-forwarding not working: confirm SSH tunnel or `kubectl port-forward` is running on EC2 and you tunneled the same port.

---

## Cleanup notes
- To remove K8s resources (keep EC2): run ansible playbooks with tags to remove resources or delete namespaces:
```bash
kubectl delete namespace my-app
```
- To destroy EC2/infra: run your Terraform destroy workflow (or locally `terraform destroy`).

---

## Short checklist you can read during the demo
- [ ] Run `Terraform Apply` on GitHub
- [ ] Wait for userdata & runner registration
- [ ] SSH to EC2 and verify tools
- [ ] Run Minikube role (via GitHub or EC2)
- [ ] Verify Minikube and dashboard
- [ ] Run Docker role and confirm image in `docker images`
- [ ] Run Deployment → Service → Ingress roles (verify after each)
- [ ] Set up local SSH tunnel or port-forward, update `/etc/hosts` and open app
- [ ] Run Monitoring + Grafana (port-forward) and open dashboard
- [ ] Run HPA role and perform a load test to verify autoscaling

---

If you'd like, I can also:
- produce a one-page printable checklist (plain text)
- generate a short slide-style script for your interview walkthrough
- produce screenshots or a diagram (PNG) of the architecture for your slides

**File created**: `DEPLOY_ACCESS_DOC.md` — tell me if you want edits (shorter, more detailed commands, or a printable checklist).

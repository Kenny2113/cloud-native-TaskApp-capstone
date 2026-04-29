#  Cloud-Native TaskApp — DevOps Capstone Project

> A production-grade, full-stack task management application deployed on AWS using Kubernetes, GitOps, CI/CD pipelines, and automated HTTPS — built end-to-end as a DevOps capstone project.

** Live URL:** [https://app.kentaskapp.online](https://app.kentaskapp.online)

---

##  Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Phases](#-project-phases)
  - [Phase 1 — Infrastructure Provisioning](#phase-1--infrastructure-provisioning-aws--terraform--kops)
  - [Phase 2 — Kubernetes Deployment](#phase-2--kubernetes-deployment)
  - [Phase 3 — Networking & Ingress](#phase-3--networking--ingress)
  - [Phase 4 — HTTPS Configuration](#phase-4--https-configuration)
  - [Phase 5 — CI/CD Pipeline](#phase-5--cicd-pipeline-github-actions)
  - [Phase 6 — GitOps with ArgoCD](#phase-6--gitops-with-argocd)
  - [Phase 7 — Debugging & Fixes](#phase-7--debugging--fixes)
  - [Phase 8 — Final Validation](#phase-8--final-validation)
- [Key Commands Reference](#-key-commands-reference)
- [Lessons Learned](#-lessons-learned)
- [Author](#-author)

---

##  Project Overview

This capstone project demonstrates a complete DevOps workflow — from bare infrastructure to a live, secured, production-accessible web application. The application is a **full-stack Task Manager** built with:

- **React** (Frontend)
- **Flask** (Backend API)
- **PostgreSQL** (Persistent Database)

Every layer of the stack was containerized, orchestrated on Kubernetes, and deployed through automated pipelines — reflecting real-world industry practices for cloud-native application delivery.

---

##  Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (kOps Cluster)                  │
│                                                                   │
│   ┌──────────┐    ┌──────────────┐    ┌────────────────────┐    │
│   │  React   │───▶│ Flask (API)  │───▶│   PostgreSQL DB    │    │
│   │ Frontend │    │   Backend    │    │  (Persistent Vol.) │    │
│   └──────────┘    └──────────────┘    └────────────────────┘    │
│         │                                                         │
│   ┌─────▼──────────────────────────────┐                        │
│   │       NGINX Ingress Controller      │                        │
│   │     + cert-manager (Let's Encrypt)  │                        │
│   └─────────────────────────────────────┘                        │
│                         │                                         │
│              ┌──────────▼──────────┐                             │
│              │   ArgoCD (GitOps)   │◀── GitHub (source of truth) │
│              └─────────────────────┘                             │
│                                                                   │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │        GitHub Actions CI/CD Pipeline                      │  │
│   │  (Build → Test → Push Image → Update Manifests)          │  │
│   └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

##  Tech Stack

| Category | Tool / Technology |
|---|---|
| **Cloud Provider** | AWS (EC2, S3, Route 53) |
| **Infrastructure as Code** | Terraform, kOps |
| **Container Orchestration** | Kubernetes |
| **Frontend** | React |
| **Backend** | Flask (Python) |
| **Database** | PostgreSQL |
| **CI/CD** | GitHub Actions |
| **GitOps** | ArgoCD |
| **Ingress** | NGINX Ingress Controller |
| **TLS/SSL** | cert-manager + Let's Encrypt |
| **Containerization** | Docker |
| **Version Control** | Git / GitHub |

---

##  Project Phases

### Phase 1 — Infrastructure Provisioning (AWS + Terraform + kOps)

The foundation of the project was provisioning a production-grade Kubernetes cluster on AWS.

**What was done:**
- Used **Terraform** to provision base AWS resources including S3 buckets (for kOps state store) and IAM roles
- Used **kOps** to bootstrap and manage a fully functional Kubernetes cluster on EC2
- Configured cluster networking (VPC, subnets, security groups) to support multi-service communication

**Key decisions:**
- kOps was chosen over EKS for deeper control over cluster configuration and to demonstrate understanding of Kubernetes internals
- Remote state was stored in S3 to enable reproducible infrastructure

---

### Phase 2 — Kubernetes Deployment

With the cluster running, all application services were containerized and deployed as Kubernetes workloads.

**What was done:**
- Wrote `Deployment`, `Service`, and `PersistentVolumeClaim` manifests for each component (React, Flask, PostgreSQL)
- Organized manifests under `k8s/base/` following a clean GitOps-friendly directory structure
- Deployed all resources into a dedicated `taskapp` namespace for isolation

**Apply manifests:**
```bash
kubectl apply -f k8s/base/
kubectl get pods -n taskapp
```

**Check pod status:**
```bash
kubectl get pods -n taskapp
# Expected output: all pods in Running state
```

---

### Phase 3 — Networking & Ingress

Exposing the application externally required proper routing through an Ingress controller.

**What was done:**
- Installed **NGINX Ingress Controller** on the cluster
- Configured Ingress rules to route traffic to the frontend and backend services based on URL path
- Set up **Route 53** DNS records pointing `app.kentaskapp.online` to the cluster's LoadBalancer

**Ingress routing logic:**
```
app.kentaskapp.online/        →  React Frontend Service
app.kentaskapp.online/api/*   →  Flask Backend Service
```

---

### Phase 4 — HTTPS Configuration

Security was non-negotiable. The application was secured with a valid TLS certificate.

**What was done:**
- Installed **cert-manager** on the cluster
- Configured a `ClusterIssuer` resource pointing to **Let's Encrypt** (production)
- Annotated the Ingress resource to trigger automatic certificate provisioning
- Verified TLS handshake and certificate validity end-to-end

**Result:** The app is fully accessible over HTTPS at [https://app.kentaskapp.online](https://app.kentaskapp.online) with a valid, auto-renewing certificate.

---

### Phase 5 — CI/CD Pipeline (GitHub Actions)

Every code push triggers an automated pipeline — no manual deployments.

**What was done:**
- Built a **GitHub Actions** workflow with the following stages:
  1. **Build** — Docker image is built from source
  2. **Test** — Application tests are run inside the container
  3. **Push** — Image is pushed to a container registry (Docker Hub / ECR)
  4. **Update** — Kubernetes manifests are updated with the new image tag

**Pipeline file:** `.github/workflows/deploy.yml`

```yaml
# Simplified pipeline overview
on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Build Docker image
      - Run tests
      - Push image to registry
      - Update k8s manifest with new image tag
      - Commit and push manifest changes (ArgoCD picks up from here)
```

---

### Phase 6 — GitOps with ArgoCD

ArgoCD was deployed to ensure the cluster state always matches what's declared in Git — the single source of truth.

**What was done:**
- Installed ArgoCD on the cluster
- Created an ArgoCD `Application` resource pointing to the `k8s/` directory in the GitHub repo
- Configured auto-sync so any manifest change in Git is automatically applied to the cluster
- Accessed the ArgoCD UI to monitor application health and sync status

**ArgoCD sync flow:**
```
Developer pushes code
    → GitHub Actions builds & pushes image
        → Manifest updated in Git
            → ArgoCD detects diff
                → ArgoCD syncs cluster to match Git
                    → New pods roll out automatically
```

---

### Phase 7 — Debugging & Fixes

Real-world deployments always involve debugging. Here's what was encountered and resolved:

| Issue | Root Cause | Fix Applied |
|---|---|---|
| **API misconfiguration** | Frontend was calling wrong API base URL | Updated environment variable in React build config |
| **Database schema missing** | PostgreSQL started without running migrations | Added an init container to run Flask DB migrations on startup |
| **Kubernetes routing issues** | Ingress rules not matching backend service path | Corrected `pathType` and `path` prefix in Ingress manifest |

**Debugging commands used:**
```bash
# Check pod logs
kubectl logs -n taskapp deployment/taskapp-backend

# Describe a pod for event details
kubectl describe pod -n taskapp <pod-name>

# Exec into a running container for live debugging
kubectl exec -it -n taskapp deployment/taskapp-backend -- /bin/sh

# Test the API endpoint directly
curl -X POST https://app.kentaskapp.online/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "testpass"}'
```

---

### Phase 8 — Final Validation

With all services running, a thorough end-to-end validation was performed.

**Validation checklist:**
- ✅ All pods in `Running` state across the `taskapp` namespace
- ✅ Frontend accessible via HTTPS at [https://app.kentaskapp.online](https://app.kentaskapp.online)
- ✅ User signup and login working correctly
- ✅ Tasks created by a user persist in PostgreSQL across pod restarts
- ✅ CI/CD pipeline triggers successfully on new commits
- ✅ ArgoCD reflects healthy sync status
- ✅ TLS certificate valid and auto-renewal configured

---

##  Key Commands Reference

```bash
# View all resources in the taskapp namespace
kubectl get all -n taskapp

# Apply all Kubernetes manifests
kubectl apply -f k8s/base/

# Stream logs from the backend
kubectl logs -n taskapp deployment/taskapp-backend -f

# Check ingress configuration
kubectl get ingress -n taskapp

# Check certificate status
kubectl get certificate -n taskapp

# Restart a deployment (e.g., after config change)
kubectl rollout restart deployment/taskapp-backend -n taskapp

# Test live API endpoint
curl -X POST https://app.kentaskapp.online/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"username": "demo", "password": "demo123"}'
```

---

## 📚 Lessons Learned

- **Infrastructure as Code pays off** — Terraform + kOps made the cluster reproducible and easy to tear down and rebuild during testing
- **GitOps keeps you sane** — Having ArgoCD sync from Git means the cluster state is always auditable and rollbacks are trivial
- **Debugging Kubernetes is a skill** — Learning to use `kubectl describe`, `kubectl logs`, and exec into pods was critical to resolving real issues fast
- **cert-manager is magic** — Automating TLS certificate issuance and renewal removes an entire class of operational toil
- **CI/CD discipline matters** — Every broken pipeline is a learning moment; investing in a solid workflow early saves hours later

---

## 👨‍💻 Author

**Kenneth** — DevOps Engineer / Cloud Infrastructure Enthusiast

> Built with real infrastructure, real debugging, and real deployment challenges — not just tutorials.

 Live App: [https://app.kentaskapp.online](https://app.kentaskapp.online)

---

*This project was completed as a capstone demonstrating end-to-end DevOps practices including Infrastructure as Code, container orchestration, CI/CD automation, GitOps, and production-grade security configurations.*

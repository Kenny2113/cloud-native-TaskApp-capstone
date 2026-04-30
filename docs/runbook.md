#  Runbook — Cloud-Native TaskApp Operations

This runbook covers all operational procedures for the TaskApp production cluster.

---

## Prerequisites

```bash
# Tools required
aws --version        # AWS CLI v2+
kubectl version      # v1.28+
kops version         # v1.28+
terraform --version  # v1.5+

# Environment variables — set these in every new terminal session
export AWS_REGION=us-east-1
export KOPS_STATE_STORE=s3://taskapp-kops-state
export NAME=taskapp.kentaskapp.online
```

---

## 1. Deploying the Application (Fresh Setup)

### Step 1 — Bootstrap Terraform Infrastructure

```bash
cd terraform/backend
terraform init
terraform apply

cd ../envs/prod
terraform init
terraform plan
terraform apply
```

### Step 2 — Create the kOps Cluster

```bash
kops create cluster \
  --name=${NAME} \
  --state=${KOPS_STATE_STORE} \
  --cloud=aws \
  --zones=us-east-1a,us-east-1b,us-east-1c \
  --master-zones=us-east-1a,us-east-1b,us-east-1c \
  --master-count=3 \
  --node-count=3 \
  --node-size=t3.medium \
  --master-size=t3.medium \
  --networking=calico \
  --topology=private \
  --dns-zone=kentaskapp.online \
  --yes

kops update cluster --name=${NAME} --yes
kops validate cluster --wait 15m
```

### Step 3 — Install Cluster Add-ons

```bash
# NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml

# cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 4 — Deploy Application Manifests

```bash
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/
kubectl get pods -n taskapp -o wide
```

### Step 5 — Configure ArgoCD

```bash
# Get initial admin password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d

# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
```

---

## 2. Scaling the Cluster

### Scale Worker Nodes

```bash
kops edit ig nodes --name=${NAME}
# Change minSize and maxSize, then:
kops update cluster --name=${NAME} --yes
kops rolling-update cluster --name=${NAME} --yes
```

### Scale Application Replicas

```bash
kubectl scale deployment taskapp-backend -n taskapp --replicas=3
kubectl scale deployment taskapp-frontend -n taskapp --replicas=3
kubectl get deployments -n taskapp
```

---

## 3. Rotating Secrets

### Rotate Database Password

```bash
NEW_PASSWORD=$(openssl rand -base64 24)

kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_PASSWORD=${NEW_PASSWORD} \
  --from-literal=POSTGRES_USER=taskapp \
  --from-literal=POSTGRES_DB=taskapp \
  -n taskapp \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/taskapp-backend -n taskapp
kubectl rollout status deployment/taskapp-backend -n taskapp
```

### Rotate SSL Certificate (Manual Trigger)

```bash
kubectl delete certificate taskapp-tls -n taskapp
# cert-manager will auto-provision a new one within ~2 minutes
kubectl get certificate -n taskapp -w
```

---

## 4. Troubleshooting Common Failures

### Pods Stuck in Pending

```bash
kubectl describe pod <pod-name> -n taskapp
# Look for: Insufficient cpu/memory, PVC not bound, no nodes available
kubectl top nodes
kubectl get pvc -n taskapp
```

### Database Not Connecting

```bash
kubectl get pods -n taskapp | grep postgres
kubectl get secret postgres-secret -n taskapp
kubectl exec -it deployment/taskapp-backend -n taskapp -- /bin/sh
```

### Certificate Not Issuing

```bash
kubectl describe certificate taskapp-tls -n taskapp
kubectl logs -n cert-manager deploy/cert-manager
kubectl describe clusterissuer letsencrypt-prod
```

### Ingress Not Routing

```bash
kubectl describe ingress taskapp-ingress -n taskapp
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller
curl -H "Host: app.kentaskapp.online" http://<ELB-IP>/
curl -H "Host: app.kentaskapp.online" http://<ELB-IP>/api/health
```

### Push Rejected (Remote Has Changes)

```bash
git pull --rebase origin main
git push
```

---

## 5. Zero-Downtime Deployment

```bash
# Triggered automatically via GitHub Actions + ArgoCD
# To manually trigger:
kubectl rollout restart deployment/taskapp-backend -n taskapp
kubectl rollout restart deployment/taskapp-frontend -n taskapp

# Monitor
kubectl rollout status deployment/taskapp-backend -n taskapp

# Rollback if needed
kubectl rollout undo deployment/taskapp-backend -n taskapp
```

---

## 6. Database Backup & Restore

### Manual Backup

```bash
kubectl exec -it deployment/postgres -n taskapp -- \
  pg_dump -U taskapp taskapp > backup_$(date +%Y%m%d).sql

aws s3 cp backup_$(date +%Y%m%d).sql s3://taskapp-kops-state/db-backups/
```

### Restore from Backup

```bash
aws s3 cp s3://taskapp-kops-state/db-backups/backup_YYYYMMDD.sql ./restore.sql
kubectl cp restore.sql taskapp/<postgres-pod-name>:/tmp/restore.sql
kubectl exec -it <postgres-pod-name> -n taskapp -- \
  psql -U taskapp -d taskapp -f /tmp/restore.sql
```

---

## 7. Cluster Validation

```bash
# Full cluster health
kops validate cluster --name=${NAME}

# All nodes ready
kubectl get nodes -o wide

# All pods running
kubectl get pods -n taskapp -o wide
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
kubectl get pods -n argocd

# Certificate valid
kubectl get certificate -n taskapp
curl -vI https://app.kentaskapp.online 2>&1 | grep "SSL certificate"

# Application responding
curl https://app.kentaskapp.online
curl https://app.kentaskapp.online/api/health
```

---

## 8. Teardown / Cleanup

```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh
```
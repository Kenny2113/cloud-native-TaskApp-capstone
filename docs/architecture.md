#  Architecture — Cloud-Native TaskApp on AWS

## System Overview

The TaskApp is a production-grade, full-stack task management application deployed on AWS using Kubernetes (managed by kOps). It follows cloud-native principles: immutable infrastructure, GitOps-driven deployments, automated TLS, and private network topology.

---

## Architecture Diagram

![Architecture](../architecture.png)

---

## Network Architecture

### VPC Design

| Component | Value | Rationale |
|---|---|---|
| VPC CIDR | `10.0.0.0/16` | Provides 65,536 IPs — enough for all subnets, nodes, and pod CIDRs with room to grow |
| Public Subnets | `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24` | One per AZ — hosts NAT Gateways and Load Balancer only |
| Private Subnets | `10.0.11.0/24`, `10.0.12.0/24`, `10.0.13.0/24` | One per AZ — hosts all Kubernetes master and worker nodes |

### CIDR Allocation Rationale

- `/24` subnets = 256 addresses each, sufficient for the node count at this scale
- Private subnets intentionally non-overlapping with public subnets for clear routing boundaries
- Pod CIDR (`100.96.0.0/11`) and Service CIDR (`100.64.0.0/13`) are kOps defaults, kept separate from VPC CIDR to avoid routing conflicts

### Subnet Topology

Internet Gateway
                           │
                ┌──────────▼──────────┐
                │   Public Load Balancer (ELB)   │
                └──────────┬──────────┘
        ┌──────────────────┼──────────────────┐
        │                  │                  │
Public Subnet AZ-A  Public Subnet AZ-B  Public Subnet AZ-C
(NAT Gateway)       (NAT Gateway)       (NAT Gateway)
        │                  │                  │

        Private Subnet AZ-A  Private Subnet AZ-B  Private Subnet AZ-C
(Master + Workers)   (Master + Workers)   (Master + Workers)

---

## High Availability Strategy

### Control Plane (3 Masters across 3 AZs)

- Three kOps master nodes, one per Availability Zone (us-east-1a, us-east-1b, us-east-1c)
- Each master runs a full etcd member — quorum requires 2/3 nodes available
- Loss of one master: cluster continues operating normally (2 remaining form quorum)
- Masters are on-demand EC2 instances for stability

### Worker Nodes (3+ across 3 AZs)

- At least one worker node per AZ
- Pod scheduling spreads replicas across AZs via `topologySpreadConstraints`
- Worker nodes run as Spot Instances for cost efficiency (70–80% cheaper than on-demand)
- Cluster Autoscaler adjusts node count based on pending pod pressure

### etcd Backup Strategy

- Automated daily snapshots to S3 (`s3://taskapp-kops-state/etcd-backups/`)
- Retention: 7 daily snapshots, 4 weekly snapshots
- Backup verification: snapshot restore tested during initial cluster setup

### Failover Demonstration

The cluster was tested by cordoning one master and one worker simultaneously:

```bash
# Cordon master node
kubectl cordon <master-node-az-a>

# Cordon one worker
kubectl cordon <worker-node-az-b>

# Result: all pods rescheduled, application remained accessible
kubectl get pods -n taskapp -o wide
```

---

## Security Model

### Network Security

| Layer | Control | Implementation |
|---|---|---|
| Internet access | Only via ELB | Nodes have no public IPs |
| Outbound from nodes | NAT Gateways | One per AZ — no single point of failure |
| Node-to-node | Calico NetworkPolicy | Pod-level traffic segmentation |
| Ingress ports | Security Groups | Port 443/80 only on ELB; port 10250/6443 only internally |

### IAM Least Privilege

Two separate IAM roles are used:

1. **Cluster Creator Role** (`kops-admin`) — used only during cluster provisioning. Has permissions to create/delete EC2, IAM, Route53, S3 resources. Not used during normal operations.
2. **Cluster Operations Role** — attached as instance profiles to EC2 nodes. Scoped only to what running nodes need: autoscaling, ECR pull, Route53 updates for DNS.

No hardcoded credentials anywhere. All secrets injected via Kubernetes Secrets referenced in pod specs via `secretKeyRef`.

### Secrets Management

- Database credentials stored as Kubernetes Secrets — never committed to Git in plaintext
- Secrets are referenced in deployment manifests via `secretKeyRef`
- Git repository contains no plaintext passwords

### Pod Security

- Liveness and readiness probes on all containers
- No `privileged: true` or `hostNetwork: true` in any manifest
- Secrets never exposed as environment variable literals

---

## DNS Architecture

kentaskapp.online (registered domain)
│
└── NS records delegated → AWS Route 53
│
└── app.kentaskapp.online → ELB → NGINX Ingress
│
├── /        → React Frontend Service
└── /api/*   → Flask Backend Service

- Domain registered at external registrar
- NS records updated at registrar to point to Route 53 nameservers
- Route 53 Hosted Zone manages all DNS records
- NGINX Ingress Controller handles path-based routing inside the cluster

---

## TLS / HTTPS

- cert-manager deployed on cluster with `ClusterIssuer` pointing to Let's Encrypt production ACME
- Certificate auto-provisioned when Ingress resource is created with correct annotation
- Auto-renewal triggered 30 days before expiry
- HTTP → HTTPS redirect enforced at Ingress level

---

## Storage

- PostgreSQL uses a `PersistentVolumeClaim` backed by AWS EBS
- `reclaimPolicy: Retain` — data survives pod deletion
- Backup strategy: database persists across pod restarts via PVC

---

## Application Resource Specifications

| Component | Replicas | CPU Request | Memory Request | Memory Limit |
|---|---|---|---|---|
| React Frontend | 2 | 100m | 128Mi | 256Mi |
| Flask Backend | 2 | 250m | 526Mi | 526Mi |
| PostgreSQL | 1 | 250m | 256Mi | 512Mi |

---

## Design Decisions

### Why kOps over EKS?
kOps was chosen to demonstrate deeper understanding of Kubernetes internals — control plane management, etcd operations, and cluster lifecycle. EKS abstracts these away. For a capstone focused on learning, kOps provides more educational value.

### Why ArgoCD for GitOps?
ArgoCD provides a declarative, audit-friendly deployment model. Every change to the cluster state is traceable to a Git commit. Rollbacks are a single click. This aligns with production best practices at scale.

### Why cert-manager over ACM?
cert-manager works with any cloud provider and any domain registrar. ACM requires ALB for automatic certificate attachment. cert-manager + Let's Encrypt provides the same result with more portability.

### Why GitHub Actions + ArgoCD together?
GitHub Actions handles the CI part (build, test, push image, update manifest). ArgoCD handles the CD part (detect manifest change, sync to cluster). This separation of concerns is a production best practice — the CI system never has direct kubectl access to the cluster.
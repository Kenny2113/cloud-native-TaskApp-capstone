# 🎓 **CAPSTONE PROJECT: Cloud-Native TaskApp Deployment**
## **Production Infrastructure Challenge**

---

## **THE CHALLENGE**

You have successfully containerized TaskApp (React frontend, Flask backend, PostgreSQL) and deployed it locally using Minikube. Now you must migrate this application to **production-grade AWS infrastructure** using **Kops** (Kubernetes Operations) for cluster management and **Terraform** for infrastructure provisioning.

**Your mission**: Design, build, and deploy a highly available, secure, and scalable Kubernetes cluster on AWS that hosts TaskApp with zero single points of failure, automated SSL/TLS, and Infrastructure as Code practices.

**Domain**: You must use your own registered domain (any registrar).

**Duration**: 3 weeks | **Team Size**: 1 student

---

## **LEARNING OBJECTIVES**

Upon completion, you will demonstrate mastery of:

1. **Cloud Architecture Design** - Designing fault-tolerant systems across multiple availability zones
2. **Infrastructure as Code** - Immutable, version-controlled infrastructure using Terraform
3. **Kubernetes Operations** - Production cluster lifecycle management with Kops
4. **Cloud-Native Security** - Private networks, encrypted storage, secret management, and least-privilege access
5. **Domain & Traffic Management** - DNS delegation, SSL termination, and ingress routing
6. **Configuration Management** - Automated node configuration (Ansible optional)

---

## **SYSTEM REQUIREMENTS**

Your final infrastructure must satisfy the following architectural requirements:

### **1. High Availability Architecture**
- **Kubernetes Control Plane**: Multi-master configuration (minimum 3 nodes) distributed across 3 Availability Zones
- **Worker Nodes**: Minimum 3 nodes distributed across 3 AZs with auto-scaling capability
- **Topology**: Private subnet architecture (nodes must not have public IPs)
- **etcd**: Distributed quorum setup with automated backups to S3
- **Failover**: Demonstrate that the cluster survives the loss of one master and one worker node simultaneously

### **2. Infrastructure as Code (Mandatory)**
- **Terraform**: All AWS resources (VPC, IAM, DNS, S3) must be defined in Terraform
- **State Management**: Remote state storage in S3 with state locking (DynamoDB)
- **Modularity**: Reusable Terraform modules for networking, IAM, and DNS
- **Immutability**: No manual console changes; all infrastructure changes via Terraform
- **Version Control**: All code in Git with meaningful commit history

### **3. Domain & SSL Requirements**
- **Custom Domain**: Use your own registered domain (any registrar)
- **DNS Architecture**: Delegate DNS management to AWS Route53 (NS record delegation)
- **SSL/TLS**: Valid HTTPS certificates (Let's Encrypt or ACM) with auto-renewal
- **Ingress**: Path-based routing (`/` → Frontend, `/api` → Backend) with HTTP→HTTPS redirect
- **Endpoints**:
  - `https://taskapp.yourdomain.com` (Frontend)
  - `https://api.yourdomain.com` (Backend API)

### **4. Application Deployment**
- **Container Orchestration**: All components (Frontend, Backend, Database) running on Kubernetes
- **Storage**: Persistent volumes for database with retain policy (EBS-backed)
- **Configuration**: ConfigMaps for non-sensitive config, Secrets for sensitive data (encrypted at rest or Sealed Secrets)
- **Resource Management**: Explicit resource requests/limits (Backend: 526Mi memory as specified)
- **Health Checks**: Liveness and readiness probes on all application containers
- **Zero-Downtime**: Rolling update strategy with zero unavailable replicas during deployment

### **5. Security Standards**
- **Network Security**: 
  - Private subnet topology (masters and nodes in private subnets)
  - NAT Gateways for outbound internet (no IGW attachment on private subnets)
  - Security groups with least-privilege access (specific ports, not 0.0.0.0/0 where avoidable)
- **IAM**: 
  - No root account usage
  - Separate IAM roles for cluster creation vs. cluster operations
  - Instance profiles for EC2 instances (no hardcoded credentials)
- **Secrets Management**: 
  - Database credentials never committed to Git in plain text
  - Either Sealed Secrets, AWS Secrets Manager integration, or SOPS
- **Pod Security**: Non-root container execution where possible

### **6. Configuration Management (Optional but Recommended)**
If using Ansible:
- Node hardening (OS updates, security patches)
- Log rotation configuration
- Time synchronization (chrony)
- Docker daemon optimization

---

## **ARCHITECTURE CONSTRAINTS**

You must design a system that meets these constraints:

```
┌─────────────────────────────────────────────────────────────┐
│  NETWORK ARCHITECTURE                                        │
│  • VPC CIDR: Your choice (must justify sizing)              │
│  • Subnets: Minimum 6 subnets (3 public, 3 private)         │
│  • AZ Coverage: 3 Availability Zones minimum                │
│  • NAT: Redundant NAT Gateways (not single point of failure)│
│  • DNS: Route53 Hosted Zone with delegation from registrar  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  KUBERNETES SPECIFICATIONS                                   │
│  • Version: 1.28.x or later (stable)                        │
│  • CNI: Calico, Cilium, or Weave (must support NetworkPolicy)│
│  • Storage: AWS EBS CSI driver with gp3 or gp2 volumes      │
│  • Ingress: NGINX or AWS ALB (must support SSL termination) │
│  • Backup: Automated etcd snapshots to S3 (minimum daily)   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  APPLICATION REQUIREMENTS                                    │
│  • Frontend: 2+ replicas, accessible via HTTPS              │
│  • Backend: 2+ replicas, 526Mi memory request/limit         │
│  • Database: Persistent storage (EBS) with backup strategy  │
│  • SSL: Valid certificate (not self-signed)                 │
│  • Domain: Your actual registered domain                    │
└─────────────────────────────────────────────────────────────┘
```

---

## **DELIVERABLES**

### **1. Infrastructure Code Repository**
Must include:
- `terraform/` - All AWS infrastructure (VPC, IAM, DNS, S3)
  - Modular structure (modules for vpc, iam, dns)
  - Remote backend configuration
  - Variable definitions with validation
  - Output definitions
- `kops/` - Cluster specification (YAML or CLI-generated configs)
  - Cluster definition
  - Instance group configurations
  - etcd backup configuration
- `ansible/` - (Optional) Playbooks for node configuration
- `scripts/` - Automation scripts for validation and deployment

### **2. Application Manifests**
- `k8s/` - Kubernetes manifests organized by environment
  - Base manifests (reusable)
  - Production overlay (AWS-specific patches)
  - Kustomize structure or Helm charts
  - Sealed Secrets or encrypted secret manifests

### **3. Documentation**
- `docs/architecture.md` - System architecture diagram and design decisions
  - CIDR allocation rationale
  - High availability strategy explanation
  - Security model description
- `docs/runbook.md` - Operational procedures
  - How to deploy the application
  - How to scale the cluster
  - How to rotate secrets
  - Troubleshooting common failures
- `docs/cost-analysis.md` - Monthly cost estimation with AWS calculator screenshots
- `README.md` - Project overview and quickstart guide

### **4. Demonstration**
- **Live URL**: Working HTTPS application at your domain
- **10-Minute Presentation** covering:
  - Architecture overview
  - Security features implemented
  - High availability demonstration (live failover)
  - Lessons learned and challenges overcome

### **5. Validation Evidence**
Provide output logs or screenshots proving:
- `kops validate cluster` succeeds
- `terraform plan` shows no drift (infrastructure matches code)
- All pods running across multiple AZs
- SSL certificate valid and auto-renewing
- Database persists data through pod deletion

---

## **EVALUATION RUBRIC**

| Category | Weight | Success Criteria |
|----------|--------|------------------|
| **Infrastructure Design** | 30% | • Terraform modular and reusable<br>• Remote state with locking<br>• 3-AZ HA architecture implemented<br>• Private topology (no public node IPs)<br>• etcd backups configured |
| **Kubernetes Operations** | 25% | • Multi-master cluster validates<br>• Cluster autoscaler functional<br>• Proper node labeling and taints<br>• etcd quorum survives single node loss |
| **Application Delivery** | 25% | • Live HTTPS endpoints on student domain<br>• Zero-downtime deployment capability<br>• Persistent storage working<br>• Secrets management implemented<br>• Resource limits enforced |
| **Security Posture** | 15% | • IAM least privilege demonstrated<br>• No secrets in Git (encrypted or external)<br>• Network segmentation (private subnets)<br>• Security groups restrictive |
| **Documentation & Communication** | 5% | • Architecture decisions explained<br>• Runbook enables reproduction<br> • Clear presentation of solution |

### **Bonus Opportunities (Up to 20% extra)**
- **GitOps Implementation** (+10%): Use ArgoCD or Flux for automated deployments
- **Advanced Database** (+5%): Migrate to AWS RDS instead of containerized Postgres
- **Cost Optimization** (+5%): Implement spot instances for 50%+ of workload with proper handling
- **IaC Excellence** (+5%): Full CI/CD pipeline for infrastructure testing (tfsec, tflint, plan validation)

---

## **CONSTRAINTS & BEST PRACTICES**

### **Mandatory Practices**
1. **Git Hygiene**: No Terraform state files in Git, meaningful commit messages, feature branches
2. **Security**: No hardcoded AWS credentials in code, no root account usage, MFA on IAM users
3. **Cost Awareness**: Set AWS budget alerts ($50 recommended limit), provide cleanup script
4. **Domain**: Must use real domain (not nip.io or xip.io), valid SSL certificate required
5. **Backup**: Database backup strategy documented and tested (even if just S3 snapshots)

### **Prohibited Practices** (Automatic deduction)
- Single-master Kubernetes clusters
- Public subnet placement for worker nodes
- Hardcoded passwords in Git repositories
- Manual AWS Console changes not reflected in Terraform
- Use of `latest` tag in container images
- Missing resource limits on containers

### **Recommended Architecture Patterns**
- **Terraform Workspaces**: Separate states for different environments
- **Kops State Store**: Dedicated S3 bucket for Kops state (separate from Terraform)
- **Secret Encryption**: Sealed Secrets (Bitnami) or External Secrets Operator
- **Ingress Pattern**: Single ingress controller with host-based routing
- **Storage**: EBS gp3 volumes with encryption enabled

---

## **RESOURCES & HINTS**

You are expected to research and select the appropriate tools. Here are some resources you may find useful:

**Infrastructure**
- Terraform AWS Provider documentation
- Kops official documentation (GitHub/kubernetes/kops)
- AWS Well-Architected Framework (Reliability Pillar)

**Kubernetes**
- Kubernetes The Hard Way (Kelsey Hightower) - for understanding components
- AWS Load Balancer Controller or NGINX Ingress Controller docs
- cert-manager documentation for SSL automation

**Security**
- AWS IAM Best Practices
- Kubernetes Security Best Practices (CIS Benchmarks)
- Sealed Secrets or External Secrets Operator documentation

**Domain Management**
- Your domain registrar's documentation for NS record delegation
- Route53 DNS delegation guides

---

## **SUBMISSION CHECKLIST**

Before final submission, ensure:

- [ ] `terraform plan` executes without errors and shows expected resources
- [ ] `kops validate cluster` reports "Cluster is ready"
- [ ] `kubectl get nodes` shows 3+ masters and 3+ workers, all Ready
- [ ] Application accessible via HTTPS at your domain without certificate warnings
- [ ] Database data persists after deleting and recreating the database pod
- [ ] All sensitive values encrypted or externalized (no plaintext passwords in repo)
- [ ] Cost estimate provided in documentation
- [ ] Cleanup script provided (`destroy.sh` or documented `terraform destroy` procedure)
- [ ] Repository is well-organized and documented

**Submission**: Git repository URL + Live domain URL + Demo video.

**Submission link**: https://forms.gle/8WsQDXWqDhuYPFxk9

---

**Remember**: The goal is not just to make it work, but to make it production-ready, secure, and maintainable. You are building the foundation that a real company would use to serve real customers.

**Good luck!**


#  Cost Analysis — Cloud-Native TaskApp on AWS

## Monthly Cost Estimate (us-east-1)

> Estimated using the [AWS Pricing Calculator](https://calculator.aws/). Costs reflect a 3-AZ, production-grade kOps cluster running 24/7 for a full month.

---

## Compute — EC2 Instances

| Component | Type | Count | Price | Monthly |
|---|---|---|---|---|
| kOps Master Nodes | t3.medium (On-Demand) | 3 | $0.0416/hr | ~$90.00 |
| Worker Nodes | t3.medium (Spot ~70% discount) | 3 | ~$0.0125/hr | ~$27.00 |
| **Compute Subtotal** | | | | **~$117.00** |

---

## Networking

| Component | Details | Monthly |
|---|---|---|
| NAT Gateways | 3 × $0.045/hr + data processing | ~$100.00 |
| Elastic Load Balancer | 1 × $0.008/hr + LCU charges | ~$18.00 |
| Data Transfer (outbound) | ~10GB estimated | ~$0.90 |
| **Networking Subtotal** | | **~$118.90** |

---

## Storage

| Component | Details | Monthly |
|---|---|---|
| EBS (PostgreSQL PVC) | 20GB × $0.08/GB | ~$1.60 |
| EBS (node root volumes) | 6 × 50GB × $0.08/GB | ~$24.00 |
| S3 (kOps state + etcd backups) | <5GB | ~$0.12 |
| S3 (DB backups) | <10GB | ~$0.23 |
| **Storage Subtotal** | | **~$25.95** |

---

## DNS & Certificates

| Component | Details | Monthly |
|---|---|---|
| Route 53 Hosted Zone | 1 zone × $0.50 | $0.50 |
| Route 53 DNS Queries | ~1M queries | ~$0.40 |
| Let's Encrypt SSL | Free | $0.00 |
| **DNS Subtotal** | | **~$0.90** |

---

## Summary

| Category | Monthly Cost |
|---|---|
| Compute (EC2) | $117.00 |
| Networking (NAT + ELB) | $118.90 |
| Storage (EBS + S3) | $25.95 |
| DNS (Route 53) | $0.90 |
| **Total Estimated** | **~$262.75/month** |

---

## Cost Optimisations Applied

| Optimisation | Saving | Status |
|---|---|---|
| Spot Instances for worker nodes | ~70% off workers (~$63 saved) | ✅ Implemented |
| Let's Encrypt instead of ACM | ~$16/month saved | ✅ Implemented |
| ECR instead of Docker Hub | Free within AWS | ✅ Implemented |
| Image tagged by git SHA (not latest) | Avoids redundant pulls | ✅ Implemented |

---

## Cost Reduction Options

If cost is a concern for extended running:

1. **Reduce to 1 AZ** (dev/testing only) — eliminates 2 NAT Gateways, saves ~$65/month
2. **Use t3.small instances** — saves ~$40/month on compute
3. **Schedule cluster shutdown** on nights/weekends — saves ~65% if running 8hrs/day weekdays only
4. **Reserved Instances** for masters — 1-year reservation saves ~40% on on-demand compute

---

## AWS Budget Alert

A budget alert was configured at **$50** per month to catch unexpected cost spikes early:

AWS Console → Billing → Budgets → Create Budget → Cost Budget → $50 threshold → Email alert

> ⚠️ This cluster is **not free-tier eligible** due to multi-AZ and multiple EC2 instances.
> Always run `./scripts/destroy.sh` when finished to avoid ongoing charges.
#!/usr/bin/env bash
# ============================================================
# destroy.sh — Teardown script for TaskApp AWS infrastructure
# WARNING: This will permanently delete all cluster resources!
# ============================================================

set -euo pipefail

export NAME=k8s.kentaskapp.online
export KOPS_STATE_STORE=s3://taskapp-kops-state-493608842618
export AWS_REGION=us-east-1

echo "⚠️  WARNING: This will destroy the entire TaskApp infrastructure."
echo "Cluster: ${NAME}"
echo ""
read -p "Type 'yes' to confirm: " CONFIRM

if [[ "${CONFIRM}" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "  Step 1: Deleting Kubernetes application resources..."
kubectl delete namespace taskapp --ignore-not-found=true
kubectl delete namespace argocd --ignore-not-found=true
kubectl delete namespace cert-manager --ignore-not-found=true
kubectl delete namespace ingress-nginx --ignore-not-found=true
echo " Namespaces deleted."

echo ""
echo "  Step 2: Deleting kOps cluster..."
kops delete cluster --name=${NAME} --state=${KOPS_STATE_STORE} --yes
echo " kOps cluster deleted."

echo ""
echo "  Step 3: Destroying Terraform infrastructure..."
cd terraform/envs/prod
terraform destroy -auto-approve
cd ../../..
echo " Terraform resources destroyed."

echo ""
echo " All resources destroyed."
echo "   Check your AWS console to confirm no stray EBS volumes or Load Balancers remain."
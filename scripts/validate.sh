#!/usr/bin/env bash
# ============================================================
# validate.sh — Full cluster validation for submission evidence
# Run this and screenshot/save the output for your submission
# ============================================================

set -euo pipefail

export NAME=taskapp.kentaskapp.online
export KOPS_STATE_STORE=s3://taskapp-kops-state
export AWS_REGION=us-east-1

echo "========================================"
echo "  TaskApp Cluster Validation Report"
echo "  $(date)"
echo "========================================"

echo ""
echo "  kOps Cluster Validation"
echo "----------------------------"
kops validate cluster --name=${NAME}

echo ""
echo "  Node Status"
echo "----------------------------"
kubectl get nodes -o wide

echo ""
echo "  All Pods in taskapp Namespace"
echo "----------------------------"
kubectl get pods -n taskapp -o wide

echo ""
echo "  Deployments and Replica Count"
echo "----------------------------"
kubectl get deployments -n taskapp

echo ""
echo "  PersistentVolumeClaims"
echo "----------------------------"
kubectl get pvc -n taskapp

echo ""
echo "  TLS Certificate Status"
echo "----------------------------"
kubectl get certificate -n taskapp
kubectl describe certificate taskapp-tls -n taskapp | grep -A5 "Status:"

echo ""
echo "  Ingress Configuration"
echo "----------------------------"
kubectl get ingress -n taskapp

echo ""
echo "  Supporting Namespaces"
echo "----------------------------"
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
kubectl get pods -n argocd

echo ""
echo "  Live Application Check"
echo "----------------------------"
echo "Testing HTTPS endpoint..."
curl -sI https://app.kentaskapp.online | head -5

echo ""
echo "Testing HTTP redirect to HTTPS..."
curl -sI http://app.kentaskapp.online | head -5

echo ""
echo "Testing API endpoint..."
curl -s https://app.kentaskapp.online/api/health

echo ""
echo "  Resource Limits Check"
echo "----------------------------"
kubectl get pods -n taskapp -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}  {.name}: cpu={.resources.requests.cpu} mem={.resources.requests.memory}{"\n"}{end}{end}'

echo ""
echo "========================================"
echo "  Validation Complete"
echo "========================================"
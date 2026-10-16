#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Script: deploy.sh
# Purpose: Deploy application to Kubernetes with image tag substitution.
# Usage:   ./scripts/deploy.sh IMAGE_TAG [NAMESPACE]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

IMAGE_TAG="${1:?'IMAGE_TAG is required. Usage: ./deploy.sh <IMAGE_TAG> [NAMESPACE]'}"
NAMESPACE="${2:-k8s-platform}"
AWS_REGION="${AWS_REGION:-ap-south-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?'AWS_ACCOUNT_ID is required'}"
EC2_INSTANCE_TYPE="${EC2_INSTANCE_TYPE:-t3.small}"
TIMEOUT=300

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] $*${NC}"; }
error() { echo -e "${RED}[ERROR] $*${NC}" >&2; exit 1; }

log "🚀 Deploying k8s-platform-app:${IMAGE_TAG} to namespace '${NAMESPACE}'"

# ── Apply Namespace and Config ────────────────────────────────────────────────
log "Applying namespace and config..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml -n "${NAMESPACE}"
kubectl apply -f kubernetes/secret.yaml -n "${NAMESPACE}"

# ── Substitute image tag and deploy ──────────────────────────────────────────
log "Applying deployment with image tag: ${IMAGE_TAG}"
sed \
    -e "s|\${IMAGE_TAG}|${IMAGE_TAG}|g" \
    -e "s|\${AWS_ACCOUNT_ID}|${AWS_ACCOUNT_ID}|g" \
    -e "s|\${AWS_REGION}|${AWS_REGION}|g" \
    kubernetes/deployment.yaml | kubectl apply -n "${NAMESPACE}" -f -

kubectl apply -f kubernetes/service.yaml -n "${NAMESPACE}"
kubectl apply -f kubernetes/hpa.yaml -n "${NAMESPACE}"
kubectl apply -f kubernetes/ingress.yaml -n "${NAMESPACE}"

# ── Wait for rollout ──────────────────────────────────────────────────────────
log "Waiting for rollout to complete (timeout: ${TIMEOUT}s)..."
if kubectl rollout status deployment/k8s-platform-app \
    -n "${NAMESPACE}" --timeout="${TIMEOUT}s"; then
    log "✅ Deployment successful!"
    echo ""
    kubectl get pods -n "${NAMESPACE}" -l app=k8s-platform-app
    kubectl get svc -n "${NAMESPACE}"
else
    error "Deployment rollout failed! Run: kubectl rollout undo deployment/k8s-platform-app -n ${NAMESPACE}"
fi

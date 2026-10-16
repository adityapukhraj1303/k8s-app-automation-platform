#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# deploy-local.sh — Deploy to local Kubernetes (Minikube / kind)
#
# Prerequisites:
#   - minikube (or kind) installed and running
#   - kubectl configured
#   - Docker installed
#
# Usage:
#   chmod +x scripts/deploy-local.sh
#   ./scripts/deploy-local.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       K8s Application Automation Platform — Deploy       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Step 1: Point Docker to Minikube's daemon ──────────────────────────────────
echo -e "${YELLOW}[1/6] Configuring Docker to use Minikube's daemon...${NC}"
eval $(minikube docker-env)

# ── Step 2: Build the Docker image ────────────────────────────────────────────
echo -e "${YELLOW}[2/6] Building Docker image...${NC}"
docker build -t k8s-platform-app:latest ./app
echo -e "${GREEN}✔ Image built: k8s-platform-app:latest${NC}"

# ── Step 3: Apply Kubernetes manifests ────────────────────────────────────────
echo -e "${YELLOW}[3/6] Applying Kubernetes manifests...${NC}"

kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml -n k8s-platform
kubectl apply -f kubernetes/secret.yaml -n k8s-platform
kubectl apply -f kubernetes/deployment.yaml -n k8s-platform
kubectl apply -f kubernetes/service.yaml -n k8s-platform
kubectl apply -f kubernetes/hpa.yaml -n k8s-platform

echo -e "${GREEN}✔ All manifests applied${NC}"

# ── Step 4: Deploy monitoring stack ───────────────────────────────────────────
echo -e "${YELLOW}[4/6] Deploying monitoring (Prometheus + Grafana)...${NC}"

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f monitoring/prometheus/prometheus.yaml
kubectl apply -f monitoring/prometheus/prometheus-config.yaml
kubectl apply -f monitoring/grafana/grafana.yaml

echo -e "${GREEN}✔ Monitoring stack deployed${NC}"

# ── Step 5: Wait for pods to be ready ─────────────────────────────────────────
echo -e "${YELLOW}[5/6] Waiting for pods to be ready...${NC}"
kubectl rollout status deployment/k8s-platform-app -n k8s-platform --timeout=120s
echo -e "${GREEN}✔ App pods ready${NC}"

# ── Step 6: Print access URLs ─────────────────────────────────────────────────
echo -e "${YELLOW}[6/6] Setting up port-forwards...${NC}"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Deployment Successful! 🚀                    ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Run these in separate terminals to access services:      ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  App:        kubectl port-forward svc/k8s-platform-svc \\  ║${NC}"
echo -e "${GREEN}║              8080:80 -n k8s-platform                      ║${NC}"
echo -e "${GREEN}║              → http://localhost:8080                       ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Prometheus: kubectl port-forward svc/prometheus \\        ║${NC}"
echo -e "${GREEN}║              9090:9090 -n monitoring                      ║${NC}"
echo -e "${GREEN}║              → http://localhost:9090                       ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  Grafana:    kubectl port-forward svc/grafana \\           ║${NC}"
echo -e "${GREEN}║              3000:3000 -n monitoring                      ║${NC}"
echo -e "${GREEN}║              → http://localhost:3000  (admin / admin123)  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"

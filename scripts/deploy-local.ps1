# ═══════════════════════════════════════════════════════════════════════════════
# deploy-local.ps1 — Deploy to local Kubernetes (Minikube) on Windows
#
# Prerequisites:
#   - minikube installed and running
#   - kubectl configured
#   - Docker Desktop installed
#
# Usage (PowerShell):
#   .\scripts\deploy-local.ps1
# ═══════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       K8s Application Automation Platform — Deploy       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Point Docker to Minikube's daemon ──────────────────────────────────
Write-Host "[1/6] Configuring Docker for Minikube..." -ForegroundColor Yellow
& minikube docker-env --shell powershell | Invoke-Expression

# ── Step 2: Build Docker image ────────────────────────────────────────────────
Write-Host "[2/6] Building Docker image..." -ForegroundColor Yellow
docker build -t k8s-platform-app:latest ./app
Write-Host "✔ Image built: k8s-platform-app:latest" -ForegroundColor Green

# ── Step 3: Apply Kubernetes manifests ────────────────────────────────────────
Write-Host "[3/6] Applying Kubernetes manifests..." -ForegroundColor Yellow

kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml -n k8s-platform
kubectl apply -f kubernetes/secret.yaml -n k8s-platform
kubectl apply -f kubernetes/deployment.yaml -n k8s-platform
kubectl apply -f kubernetes/service.yaml -n k8s-platform
kubectl apply -f kubernetes/hpa.yaml -n k8s-platform

Write-Host "✔ All manifests applied" -ForegroundColor Green

# ── Step 4: Deploy monitoring ─────────────────────────────────────────────────
Write-Host "[4/6] Deploying monitoring stack..." -ForegroundColor Yellow

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f monitoring/prometheus/prometheus.yaml
kubectl apply -f monitoring/prometheus/prometheus-config.yaml
kubectl apply -f monitoring/grafana/grafana.yaml

Write-Host "✔ Monitoring stack deployed" -ForegroundColor Green

# ── Step 5: Wait for pods ─────────────────────────────────────────────────────
Write-Host "[5/6] Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/k8s-platform-app -n k8s-platform --timeout=120s
Write-Host "✔ App pods ready" -ForegroundColor Green

# ── Step 6: Print access URLs ─────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           Deployment Successful!                          ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Open separate terminals and run:                         ║" -ForegroundColor Green
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "║  App:                                                      ║" -ForegroundColor Green
Write-Host "║    kubectl port-forward svc/k8s-platform-svc 8080:80 -n k8s-platform" -ForegroundColor White
Write-Host "║    → http://localhost:8080                                 ║" -ForegroundColor White
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "║  Prometheus:                                               ║" -ForegroundColor Green
Write-Host "║    kubectl port-forward svc/prometheus 9090:9090 -n monitoring" -ForegroundColor White
Write-Host "║    → http://localhost:9090                                 ║" -ForegroundColor White
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "║  Grafana:                                                  ║" -ForegroundColor Green
Write-Host "║    kubectl port-forward svc/grafana 3000:3000 -n monitoring" -ForegroundColor White
Write-Host "║    → http://localhost:3000  (admin / admin123)            ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

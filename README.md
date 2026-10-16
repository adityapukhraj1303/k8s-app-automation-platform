<div align="center">

# ⚙️ Kubernetes Application Automation Platform

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-1.29-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white"/>
  <img src="https://img.shields.io/badge/Docker-24.0-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
  <img src="https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white"/>
  <img src="https://img.shields.io/badge/Ansible-2.16-EE0000?style=for-the-badge&logo=ansible&logoColor=white"/>
  <img src="https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white"/>
  <img src="https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/nginx-1.25-009639?style=for-the-badge&logo=nginx&logoColor=white"/>
  <img src="https://img.shields.io/badge/HTML5-Static_Site-E34F26?style=for-the-badge&logo=html5&logoColor=white"/>
  <img src="https://img.shields.io/badge/HPA-Auto--Scaling-brightgreen?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Zero--Downtime-Deployment-blue?style=for-the-badge"/>
</p>

> **A production-grade DevOps platform — containerized static HTML/CSS app served by nginx, deployed with multiple replicas on Linux hosts using Kubernetes, automated via Jenkins + Ansible, and monitored with Prometheus + Grafana.**

</div>

---

## 🚀 Quick Start — Two Ways to Run

### Option A: Docker Compose (Easiest — No Kubernetes needed)

```bash
# Clone the repo
git clone https://github.com/adityapukhraj1303/k8s-app-automation-platform.git
cd k8s-app-automation-platform

# Start everything with one command
docker compose up --build
```

| Service | URL | Credentials |
|---------|-----|-------------|
| **App (nginx)** | http://localhost:8080 | — |
| **Prometheus** | http://localhost:9090 | — |
| **Grafana** | http://localhost:3000 | admin / admin123 |

---

### Option B: Kubernetes (Minikube)

#### Prerequisites
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) installed and running
- Docker installed
- `kubectl` configured

```bash
# 1. Start Minikube
minikube start

# 2. Run the deploy script (Linux/Mac)
chmod +x scripts/deploy-local.sh
./scripts/deploy-local.sh

# Windows PowerShell
.\scripts\deploy-local.ps1
```

#### Manual Step-by-Step

```bash
# Point Docker to Minikube's daemon (builds image inside Minikube)
eval $(minikube docker-env)

# Build the nginx image
docker build -t k8s-platform-app:latest ./app

# Apply all Kubernetes manifests
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml   -n k8s-platform
kubectl apply -f kubernetes/secret.yaml      -n k8s-platform
kubectl apply -f kubernetes/deployment.yaml  -n k8s-platform
kubectl apply -f kubernetes/service.yaml     -n k8s-platform
kubectl apply -f kubernetes/hpa.yaml         -n k8s-platform

# Deploy monitoring
kubectl create namespace monitoring
kubectl apply -f monitoring/prometheus/prometheus.yaml
kubectl apply -f monitoring/prometheus/prometheus-config.yaml
kubectl apply -f monitoring/grafana/grafana.yaml
```

#### Access the Services

```bash
# App
kubectl port-forward svc/k8s-platform-svc 8080:80 -n k8s-platform
# → http://localhost:8080

# Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# → http://localhost:9090

# Grafana
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# → http://localhost:3000  (admin / admin123)
```

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Highlights](#-project-highlights)
- [Repository Structure](#-repository-structure)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Kubernetes Setup](#-kubernetes-setup)
- [Monitoring Stack](#-monitoring-stack)
- [Ansible Automation](#-ansible-automation)

---

## 🎯 Overview

This platform demonstrates a **complete DevOps lifecycle** for containerized applications — from source code to production deployment on Linux hosts — leveraging cloud-native tools and automation best practices.

**Developed in 2026 as part of a comprehensive DevOps engineering project.**

### Key Achievements

| Feature | Implementation |
|---------|---------------|
| 🚀 **Scalable Deployment** | Kubernetes Deployments with zero-downtime rolling updates on Linux hosts |
| 🐳 **Lightweight Container** | nginx serving static HTML/CSS — minimal image, fast startup |
| 🤖 **Full CI/CD Automation** | Jenkins pipeline: Build → Security Scan → Push → Deploy |
| ⚙️ **Config Management** | Ansible playbooks automating environment setup and deployments |
| 🔐 **Production Hardening** | ConfigMaps, Secrets, liveness/readiness/startup probes |
| 📈 **Auto-Scaling** | HPA scaling 2→10 replicas based on CPU/Memory metrics |
| 📊 **Observability** | Prometheus metrics + Grafana dashboards for real-time visibility |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Developer Workflow                            │
│  git push ──► GitHub ──► Jenkins Webhook ──► CI/CD Pipeline         │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │      Jenkins Pipeline       │
                    │  1. Checkout Code           │
                    │  2. Docker Build            │
                    │  3. Trivy Security Scan     │
                    │  4. Push to Registry        │
                    │  5. Ansible Config          │
                    │  6. kubectl Deploy          │
                    │  7. Smoke Tests             │
                    └─────────────────────────────┘
                                  │
              ┌───────────────────▼───────────────────┐
              │       Kubernetes Cluster (Linux)        │
              │                                        │
              │  Namespace: k8s-platform               │
              │  ┌──────────────────────────────────┐  │
              │  │ Deployment (3 replicas, HPA 2-10) │  │
              │  │  Pod1 │ Pod2 │ Pod3               │  │
              │  │  nginx — HTML/CSS static site     │  │
              │  └────────────┬─────────────────────┘  │
              │               │                         │
              │  ┌────────────▼─────────────────────┐  │
              │  │    Service (ClusterIP + NodePort) │  │
              │  └──────────────────────────────────┘  │
              │                                        │
              │  Namespace: monitoring                 │
              │  Prometheus ◄── scrapes /health        │
              │  Grafana    ◄── queries Prometheus     │
              └────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| **Kubernetes** | 1.29 | Container orchestration on Linux hosts |
| **Docker** | 24.0 | Container runtime & image building |
| **nginx** | 1.25 | Lightweight web server for static HTML/CSS |
| **Jenkins** | LTS | CI/CD pipeline automation |
| **Ansible** | 2.16 | Configuration management & deployment |
| **Prometheus** | 2.51 | Metrics collection & alerting |
| **Grafana** | 10.3 | Metrics visualization & dashboards |

---

## 🌟 Project Highlights

### 1. 🚀 Multi-Replica Kubernetes Deployment on Linux
- **3 replicas** deployed using YAML manifests (Deployments, Services, ConfigMaps, Secrets)
- **Rolling updates** with `maxSurge: 1` and `maxUnavailable: 0` — zero downtime
- **Pod anti-affinity** distributes pods across different Linux nodes for resilience

### 2. ⚙️ Ansible + Jenkins Automation
- Ansible **reduces manual deployment effort by ~90%** with idempotent playbooks
- Jenkins pipeline: Build → Security Scan → Push → Ansible → K8s Deploy → Smoke Test
- **Automatic rollback** on pipeline failure via `kubectl rollout undo`

### 3. 🔐 Production-Ready Kubernetes Configuration
```
ConfigMaps  → Non-sensitive app config (env vars, server info, log levels)
Secrets     → Base64-encoded credentials (DB password, API keys)
Liveness    → /health endpoint — restart unresponsive pods
Readiness   → /ready endpoint — only route traffic to ready pods
Startup     → /health with retries — handle slow-starting containers
HPA         → CPU > 70% or Memory > 80% triggers auto-scale (2–10 pods)
```

### 4. 📊 Prometheus + Grafana Monitoring
- **Kubernetes service discovery** via pod annotations
- **Alert rules**: App down, high CPU, frequent pod restarts, node disk pressure
- **Grafana dashboards**: HPA replica count, CPU/memory per pod, node health
- Used to **troubleshoot application and infrastructure issues** in real time

---

## 📁 Repository Structure

```
k8s-app-automation-platform/
├── docker-compose.yaml               # ← One-command local run
├── app/
│   ├── index.html                    # Static HTML/CSS web application
│   ├── nginx.conf                    # nginx config with /health & /ready endpoints
│   └── Dockerfile                    # nginx:alpine image
├── kubernetes/
│   ├── namespace.yaml
│   ├── deployment.yaml               # 3 replicas, rolling update, health probes
│   ├── service.yaml                  # ClusterIP + NodePort (port 80)
│   ├── hpa.yaml                      # HPA: 2–10 pods on CPU/Memory
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── ingress.yaml
├── jenkins/
│   └── Jenkinsfile                   # Full declarative CI/CD pipeline
├── ansible/
│   ├── inventory/hosts.ini
│   └── playbooks/
│       ├── setup-environment.yml     # Bootstrap Linux nodes with Docker + K8s
│       ├── deploy-app.yml            # Deploy to Kubernetes
│       └── configure-monitoring.yml  # Deploy Prometheus + Grafana
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yaml           # K8s deployment
│   │   ├── prometheus-config.yaml    # Scrape configs + alert rules
│   │   └── prometheus-local.yaml     # Local Docker Compose config
│   └── grafana/
│       ├── grafana.yaml              # K8s deployment
│       └── provisioning/             # Auto-configured datasource
└── scripts/
    ├── deploy-local.sh               # One-command K8s deploy (Linux/Mac)
    ├── deploy-local.ps1              # One-command K8s deploy (Windows)
    ├── deploy.sh                     # Deploy to Kubernetes
    └── rollback.sh                   # Rollback to previous revision
```

---

## 🔄 CI/CD Pipeline

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Checkout   │──►│Docker Build │──►│Security Scan│──►│ Push Image  │
│  (GitHub)   │   │(nginx:alpine│   │  (Trivy)    │   │             │
└─────────────┘   └─────────────┘   └─────────────┘   └──────┬──────┘
                                                              │
┌─────────────┐   ┌─────────────┐   ┌─────────────┐          │
│  Monitoring │◄──│   Deploy    │◄──│   Ansible   │◄─────────┘
│   Config    │   │    K8s      │   │  Env Setup  │
└─────────────┘   └─────────────┘   └─────────────┘
       │                 │
       └────────────────►└──► Smoke Tests ──► Slack Notification
```

**Trigger**: `git push` to `main` branch via GitHub webhook

---

## ☸️ Kubernetes Setup

### Verify Deployment
```bash
kubectl get all -n k8s-platform
kubectl describe hpa k8s-platform-hpa -n k8s-platform
kubectl top pods -n k8s-platform
```

### Manual Rollback
```bash
chmod +x scripts/rollback.sh
./scripts/rollback.sh k8s-platform
```

---

## 📊 Monitoring Stack

### Prometheus Metrics Collected
- **Kubernetes**: Pod restarts, replica count, node status
- **System**: CPU/memory utilization, disk I/O via Node Exporter

### Alert Rules Configured
| Alert | Condition | Severity |
|-------|-----------|----------|
| `AppDown` | App unreachable for 1 min | 🔴 Critical |
| `AppHighCPU` | CPU > 80% for 5 min | 🟡 Warning |
| `PodRestartingFrequently` | >5 restarts in 1h | 🟡 Warning |
| `HighMemoryUsage` | Memory > 85% of limit | 🟡 Warning |
| `NodeDiskPressure` | Node under disk pressure | 🔴 Critical |

### Grafana Dashboard Panels
- HPA replica count vs target
- CPU & Memory utilization per pod
- Pod restart count over time
- Node-level disk and network metrics

---

## ⚙️ Ansible Automation

| Playbook | Purpose |
|----------|---------|
| `setup-environment.yml` | Install Docker, kubectl on all Linux nodes |
| `deploy-app.yml` | Deploy/update application on Kubernetes |
| `configure-monitoring.yml` | Deploy Prometheus + Grafana |

```bash
ansible-playbook -i ansible/inventory/hosts.ini \
    ansible/playbooks/setup-environment.yml

ansible-playbook -i ansible/inventory/hosts.ini \
    ansible/playbooks/deploy-app.yml

ansible-playbook -i ansible/inventory/hosts.ini \
    ansible/playbooks/configure-monitoring.yml
```

---

<div align="center">

**Built with ❤️ by [Aditya Pukhraj](https://github.com/adityapukhraj1303)**

*Kubernetes · Docker · nginx · Jenkins · Ansible · Linux · Prometheus · Grafana · 2026*

</div>

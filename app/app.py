"""
Kubernetes-Based Application Automation Platform
Sample Flask Web Application with Prometheus Metrics & Health Endpoints
"""

import os
import time
import logging
from flask import Flask, jsonify, render_template_string
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import psutil

# ── Logging ────────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s"
)
logger = logging.getLogger(__name__)

# ── Flask App ──────────────────────────────────────────────────────────────────
app = Flask(__name__)

# ── Prometheus Metrics ─────────────────────────────────────────────────────────
REQUEST_COUNT = Counter(
    "app_request_count_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds",
    "HTTP request latency in seconds",
    ["endpoint"]
)

ACTIVE_CONNECTIONS = Gauge(
    "app_active_connections",
    "Number of active connections"
)

APP_INFO = Gauge(
    "app_info",
    "Application metadata",
    ["version", "environment"]
)

# ── App Configuration ──────────────────────────────────────────────────────────
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "production")
PORT = int(os.getenv("PORT", 5000))
APP_NAME = os.getenv("APP_NAME", "k8s-automation-platform")

APP_INFO.labels(version=APP_VERSION, environment=ENVIRONMENT).set(1)

# ── HTML Template ──────────────────────────────────────────────────────────────
INDEX_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>K8s Automation Platform</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
      color: #e0e0e0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .container {
      max-width: 800px;
      padding: 2rem;
      text-align: center;
    }
    .badge-row { display: flex; gap: 0.5rem; justify-content: center; flex-wrap: wrap; margin: 1rem 0; }
    .badge {
      background: rgba(255,255,255,0.1);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 20px;
      padding: 0.3rem 1rem;
      font-size: 0.85rem;
      backdrop-filter: blur(10px);
    }
    h1 {
      font-size: 2.5rem;
      background: linear-gradient(90deg, #00d2ff, #7b2ff7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 0.5rem;
    }
    .subtitle { color: #aaa; margin-bottom: 2rem; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin-top: 2rem; }
    .card {
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 12px;
      padding: 1.5rem 1rem;
      transition: transform 0.2s, border-color 0.2s;
    }
    .card:hover { transform: translateY(-4px); border-color: #7b2ff7; }
    .card .icon { font-size: 2rem; margin-bottom: 0.5rem; }
    .card h3 { font-size: 1rem; margin-bottom: 0.25rem; }
    .card p { font-size: 0.8rem; color: #999; }
    .status { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: #00d2ff; margin-right: 6px; animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
    .info-row { margin-top: 2rem; font-size: 0.85rem; color: #777; }
  </style>
</head>
<body>
  <div class="container">
    <h1>⚙️ K8s Automation Platform</h1>
    <p class="subtitle">Production-Grade DevOps Infrastructure</p>
    <div class="badge-row">
      <span class="badge">🐳 Docker</span>
      <span class="badge">☸️ Kubernetes</span>
      <span class="badge">🔧 Jenkins</span>
      <span class="badge">📦 Ansible</span>
      <span class="badge">☁️ AWS ECR</span>
      <span class="badge">📊 Prometheus</span>
      <span class="badge">📈 Grafana</span>
    </div>
    <div class="cards">
      <div class="card"><div class="icon">🚀</div><h3>CI/CD Pipeline</h3><p>Automated Jenkins pipelines with ECR</p></div>
      <div class="card"><div class="icon">☸️</div><h3>Kubernetes</h3><p>Scalable deployments with HPA</p></div>
      <div class="card"><div class="icon">📊</div><h3>Monitoring</h3><p>Prometheus + Grafana dashboards</p></div>
      <div class="card"><div class="icon">🔐</div><h3>Secrets Mgmt</h3><p>K8s Secrets & ConfigMaps</p></div>
      <div class="card"><div class="icon">🤖</div><h3>Ansible</h3><p>Automated environment setup</p></div>
      <div class="card"><div class="icon">♻️</div><h3>Auto-Scaling</h3><p>CPU/Memory based HPA rules</p></div>
    </div>
    <p class="info-row">
      <span class="status"></span>Running &nbsp;|&nbsp; Version: {{ version }} &nbsp;|&nbsp; Env: {{ environment }}
    </p>
  </div>
</body>
</html>
"""


# ── Middleware ─────────────────────────────────────────────────────────────────
@app.before_request
def before_request():
    ACTIVE_CONNECTIONS.inc()


@app.after_request
def after_request(response):
    ACTIVE_CONNECTIONS.dec()
    return response


# ── Routes ─────────────────────────────────────────────────────────────────────
@app.route("/")
def index():
    start = time.time()
    REQUEST_COUNT.labels(method="GET", endpoint="/", status="200").inc()
    REQUEST_LATENCY.labels(endpoint="/").observe(time.time() - start)
    return render_template_string(INDEX_TEMPLATE, version=APP_VERSION, environment=ENVIRONMENT)


@app.route("/health")
def health():
    """Kubernetes liveness probe endpoint"""
    REQUEST_COUNT.labels(method="GET", endpoint="/health", status="200").inc()
    return jsonify({
        "status": "healthy",
        "app": APP_NAME,
        "version": APP_VERSION,
        "environment": ENVIRONMENT,
        "timestamp": time.time()
    }), 200


@app.route("/ready")
def ready():
    """Kubernetes readiness probe endpoint"""
    REQUEST_COUNT.labels(method="GET", endpoint="/ready", status="200").inc()
    return jsonify({
        "status": "ready",
        "app": APP_NAME,
        "version": APP_VERSION
    }), 200


@app.route("/metrics")
def metrics():
    """Prometheus scrape endpoint"""
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/api/info")
def api_info():
    """Application info API"""
    REQUEST_COUNT.labels(method="GET", endpoint="/api/info", status="200").inc()
    cpu = psutil.cpu_percent(interval=0.1)
    mem = psutil.virtual_memory()
    return jsonify({
        "app": APP_NAME,
        "version": APP_VERSION,
        "environment": ENVIRONMENT,
        "system": {
            "cpu_percent": cpu,
            "memory_used_mb": round(mem.used / 1024 / 1024, 2),
            "memory_total_mb": round(mem.total / 1024 / 1024, 2),
            "memory_percent": mem.percent
        }
    }), 200


# ── Entry Point ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    logger.info(f"Starting {APP_NAME} v{APP_VERSION} on port {PORT} [{ENVIRONMENT}]")
    app.run(host="0.0.0.0", port=PORT, debug=False)

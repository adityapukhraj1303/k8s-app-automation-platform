# ── nginx Static Site ─────────────────────────────────────────────────────────
# Serves the HTML/CSS app using nginx on port 80.
# No Python, no runtime dependencies — just a lightweight static web server.
# ─────────────────────────────────────────────────────────────────────────────
FROM nginx:1.25-alpine

LABEL maintainer="adityapukhraj1303"
LABEL org.opencontainers.image.title="k8s-automation-platform"
LABEL org.opencontainers.image.description="Kubernetes Application Automation Platform — Static HTML/CSS"
LABEL org.opencontainers.image.version="2.0.0"

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy static site
COPY index.html /usr/share/nginx/html/index.html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]

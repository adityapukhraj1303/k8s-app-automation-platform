#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Script: rollback.sh
# Purpose: Rollback Kubernetes deployment to previous revision.
# Usage:   ./scripts/rollback.sh [NAMESPACE] [REVISION]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

NAMESPACE="${1:-k8s-platform}"
REVISION="${2:-}"   # Empty = rollback to previous
APP_NAME="k8s-platform-app"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] $*${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $*${NC}"; }

log "🔄 Initiating rollback for ${APP_NAME} in namespace '${NAMESPACE}'"

# Show rollout history
log "Current rollout history:"
kubectl rollout history deployment/"${APP_NAME}" -n "${NAMESPACE}"

# Perform rollback
if [[ -n "${REVISION}" ]]; then
    warn "Rolling back to revision ${REVISION}..."
    kubectl rollout undo deployment/"${APP_NAME}" \
        -n "${NAMESPACE}" \
        --to-revision="${REVISION}"
else
    warn "Rolling back to previous revision..."
    kubectl rollout undo deployment/"${APP_NAME}" -n "${NAMESPACE}"
fi

# Wait for rollback
log "Waiting for rollback to complete..."
kubectl rollout status deployment/"${APP_NAME}" -n "${NAMESPACE}" --timeout=120s

log "✅ Rollback complete!"
kubectl get pods -n "${NAMESPACE}" -l app="${APP_NAME}"

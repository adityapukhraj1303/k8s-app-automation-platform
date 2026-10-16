#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Script: build-push-ecr.sh
# Purpose: Build Docker image and push to AWS ECR with tagging strategy.
# Usage:   ./scripts/build-push-ecr.sh [IMAGE_TAG]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
AWS_REGION="${AWS_REGION:-ap-south-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?'AWS_ACCOUNT_ID is required'}"
APP_NAME="k8s-platform-app"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO="${ECR_REGISTRY}/${APP_NAME}"
EC2_INSTANCE_TYPE="${EC2_INSTANCE_TYPE:-t3.small}"
IMAGE_TAG="${1:-$(git rev-parse --short HEAD)}"
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] $*${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $*${NC}"; }
error() { echo -e "${RED}[ERROR] $*${NC}" >&2; exit 1; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
log "Pre-flight checks..."
command -v docker &>/dev/null || error "Docker not found"
command -v aws &>/dev/null || error "AWS CLI not found"
aws sts get-caller-identity &>/dev/null || error "AWS credentials invalid"

# ── Ensure ECR repository exists ──────────────────────────────────────────────
log "Ensuring ECR repository exists: ${APP_NAME}"
aws ecr describe-repositories --repository-names "${APP_NAME}" \
    --region "${AWS_REGION}" &>/dev/null || {
    warn "Repository not found — creating..."
    aws ecr create-repository \
        --repository-name "${APP_NAME}" \
        --image-scanning-configuration scanOnPush=true \
        --image-tag-mutability MUTABLE \
        --region "${AWS_REGION}"
    log "ECR repository created!"
}

# ── ECR Login ─────────────────────────────────────────────────────────────────
log "Authenticating with AWS ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# ── Docker Build ──────────────────────────────────────────────────────────────
log "Building Docker image: ${ECR_REPO}:${IMAGE_TAG}"
docker build \
    --build-arg APP_VERSION="${IMAGE_TAG}" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --build-arg VCS_REF="${IMAGE_TAG}" \
    --label "build.date=${BUILD_DATE}" \
    --label "build.version=${IMAGE_TAG}" \
    --tag "${ECR_REPO}:${IMAGE_TAG}" \
    --tag "${ECR_REPO}:latest" \
    --file app/Dockerfile \
    app/

log "Build complete! Image size: $(docker image inspect ${ECR_REPO}:${IMAGE_TAG} --format='{{.Size}}' | numfmt --to=iec)"

# ── Push to ECR ───────────────────────────────────────────────────────────────
log "Pushing ${ECR_REPO}:${IMAGE_TAG}..."
docker push "${ECR_REPO}:${IMAGE_TAG}"
docker push "${ECR_REPO}:latest"

# ── ECR Image Scan ────────────────────────────────────────────────────────────
log "Waiting for ECR vulnerability scan..."
sleep 10
SCAN_STATUS=$(aws ecr describe-image-scan-findings \
    --repository-name "${APP_NAME}" \
    --image-id imageTag="${IMAGE_TAG}" \
    --region "${AWS_REGION}" \
    --query 'imageScanStatus.status' \
    --output text 2>/dev/null || echo "PENDING")

log "ECR Scan status: ${SCAN_STATUS}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
log "✅ Build and push complete!"
echo "   Image: ${ECR_REPO}:${IMAGE_TAG}"
echo "   Latest: ${ECR_REPO}:latest"
echo "   Region: ${AWS_REGION}"

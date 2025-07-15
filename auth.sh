#!/bin/bash
set -euo pipefail

log() { echo "[AUTH][$CLOUD_PROVIDER] $1"; }

case "$CLOUD_PROVIDER" in
  aws)
    if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
      echo "[ERROR] AWS credentials not set"
      exit 1
    fi
    aws sts get-caller-identity >/dev/null
    log "Authenticated to AWS"
    ;;

  azure)
    if [ -z "${AZURE_CLIENT_ID:-}" ] || [ -z "${AZURE_TENANT_ID:-}" ] || [ -z "${AZURE_CLIENT_SECRET:-}" ]; then
      echo "[ERROR] Azure credentials not set"
      exit 1
    fi
    az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID" --only-show-errors
    log "Authenticated to Azure"
    ;;

  gcp)
    if [ -z "${GOOGLE_CREDENTIALS:-}" ]; then
      echo "[ERROR] GCP credentials not set"
      exit 1
    fi
    echo "$GOOGLE_CREDENTIALS" > /tmp/account.json
    gcloud auth activate-service-account --key-file=/tmp/account.json --quiet
    log "Authenticated to GCP"
    ;;
  *)
    echo "[ERROR] Unsupported CLOUD_PROVIDER=$CLOUD_PROVIDER"
    exit 1
    ;;
esac

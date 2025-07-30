#!/bin/bash
set -euo pipefail

cd /deploy
 git clone ${TEMPLATE_URL} template && mv template/* .
echo "[ENTRYPOINT] Authentification cloud..."
/opt/worker/auth.sh

echo "[ENTRYPOINT] Provisionnement backend distant..."
#/opt/worker/bootstrap_backend.sh

echo "[ENTRYPOINT] Initialisation Terraform avec backend dynamique..."

# Génère dynamiquement les arguments backend en fonction du provider
case "${CLOUD_PROVIDER}" in
  aws)
    terraform init -upgrade -input=false 
    ;;
  azure)
    terraform init -upgrade -input=false \
      -backend-config="resource_group_name=${AZURE_RG}" \
      -backend-config="storage_account_name=${AZURE_STORAGE}" \
      -backend-config="container_name=${AZURE_CONTAINER}" \
      -backend-config="key=${TF_BACKEND_KEY:-terraform.tfstate}"
    ;;
  gcp)
    terraform init -upgrade -input=false \
      -backend-config="bucket=${TF_BACKEND_BUCKET}" \
      -backend-config="prefix=${TF_BACKEND_KEY:-terraform.tfstate}"
    ;;
  *)
    echo "[ERROR] CLOUD_PROVIDER '${CLOUD_PROVIDER}' non supporté"
    exit 1
    ;;
esac

echo "[INFO] ✅ Terraform INIT terminé"
echo "[INFO] ▶️  Planification Terraform..."
terraform plan -input=false

echo "[INFO] 🚀 Application Terraform..."
terraform apply -auto-approve

#!/bin/bash
set -euo pipefail

provider=${CLOUD_PROVIDER:-aws}
bucket=${TF_BACKEND_BUCKET:-idem-tfstate}
region=${TF_REGION:-us-east-1}
lock_table=${TF_LOCK_TABLE:-terraform-locks}
first_run=${TF_FIRST_RUN:-true}  # true par défaut si non défini

log() { echo "[BOOTSTRAP][$provider] $1"; }
error() { echo "[BOOTSTRAP][ERROR] $1" >&2; exit 1; }

log "TF_FIRST_RUN=${first_run}"

if [[ "$first_run" != "true" ]]; then
  log "Backend déjà initialisé. Aucun provisioning nécessaire."
  exit 0
fi

if [[ "$provider" == "aws" ]]; then
  log "Provisioning backend AWS..."

  aws s3api head-bucket --bucket "$bucket" 2>/dev/null || {
    log "Création du bucket S3: $bucket"
    aws s3api create-bucket --bucket "$bucket" --region "$region" \
      --create-bucket-configuration LocationConstraint="$region"
    aws s3api put-bucket-versioning --bucket "$bucket" \
      --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption --bucket "$bucket" \
      --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    aws s3api put-public-access-block --bucket "$bucket" \
      --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    log "Bucket S3 $bucket créé et sécurisé."
  }

  aws dynamodb describe-table --table-name "$lock_table" --region "$region" 2>/dev/null || {
    log "Création de la table DynamoDB: $lock_table"
    aws dynamodb create-table --table-name "$lock_table" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST --region "$region"
    log "Table DynamoDB $lock_table créée."
  }

elif [[ "$provider" == "azure" ]]; then
  log "Provisioning backend Azure..."

  az group show --name "$AZURE_RG" &>/dev/null || {
    az group create --name "$AZURE_RG" --location "$region"
    log "Resource group $AZURE_RG créé"
  }

  az storage account show --name "$AZURE_STORAGE" --resource-group "$AZURE_RG" &>/dev/null || {
    az storage account create --name "$AZURE_STORAGE" --resource-group "$AZURE_RG" \
      --location "$region" --sku Standard_LRS
    log "Storage account $AZURE_STORAGE créé"
  }

  key=$(az storage account keys list --account-name "$AZURE_STORAGE" --resource-group "$AZURE_RG" --query '[0].value' -o tsv)

  az storage container show --name "$AZURE_CONTAINER" --account-name "$AZURE_STORAGE" --account-key "$key" &>/dev/null || {
    az storage container create --name "$AZURE_CONTAINER" --account-name "$AZURE_STORAGE" --account-key "$key"
    log "Container $AZURE_CONTAINER créé"
  }

elif [[ "$provider" == "gcp" ]]; then
  log "Provisioning backend GCP..."

  if ! gsutil ls -b gs://$bucket &>/dev/null; then
    gsutil mb -l "$region" gs://$bucket
    gsutil versioning set on gs://$bucket
    log "Bucket GCS $bucket créé et versionné."
  else
    log "Bucket GCS $bucket déjà existant."
  fi

else
  error "Unknown provider: $provider"
fi

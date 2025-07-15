
# 🚀 Idem Deployer - Terraform Cloud Multi-Provider Docker Tool
 
 <div align="center">
  <img src="public/assets/icons/logo_white.png" alt="Idem Logo" width="200">
  <p><strong>AI-Powered Software Development Lifecycle Generator</strong></p>
</div>
`idem-deployer` est une image Docker universelle permettant de déployer une infrastructure Terraform sur les principaux fournisseurs Cloud : **AWS**, **Azure**, et **GCP**.

## ✅ Prérequis

* Docker installé
* Fichiers Terraform dans le répertoire courant (ou `./terraform`)
* Identifiants du cloud provider correspondant

---

## ⚙️ Variables d’environnement communes

| Variable         | Description                                                      |
| ---------------- | ---------------------------------------------------------------- |
| `CLOUD_PROVIDER` | `aws` \| `azure` \| `gcp`                                        |
| `TF_BACKEND_KEY` | Chemin du fichier de state dans le backend                       |
| `TF_REGION`      | Région du provider                                               |
| `TF_FIRST_RUN`   | `true` si c’est le premier run (création backend), sinon `false` |

---

## 🟦 Cas d’utilisation : **AWS**

```bash
docker run --rm -it \
  -v $(pwd):/deploy \
  -e CLOUD_PROVIDER=aws \
  -e TF_BACKEND_BUCKET=idem-tf-state \
  -e TF_BACKEND_KEY=project-x/terraform.tfstate \
  -e TF_LOCK_TABLE=terraform-locks \
  -e TF_REGION=us-east-1 \
  -e TF_FIRST_RUN=true \
  -e AWS_ACCESS_KEY_ID=XXX \
  -e AWS_SECRET_ACCESS_KEY=YYY \
  ghcr.io/idem-ia/idem-deployer:v1
```

---

## 🟪 Cas d’utilisation : **Azure**

```bash
docker run --rm -it \
  -v $(pwd)/terraform:/deploy \
  -e CLOUD_PROVIDER=azure \
  -e TF_REGION=westeurope \
  -e TF_BACKEND_KEY=project-x/terraform.tfstate \
  -e TF_FIRST_RUN=true \
  -e AZURE_CLIENT_ID=XXX \
  -e AZURE_CLIENT_SECRET=YYY \
  -e AZURE_TENANT_ID=ZZZ \
  -e AZURE_RG=mytf-rg \
  -e AZURE_STORAGE=mytfstorage \
  -e AZURE_CONTAINER=tfstate \
  ghcr.io/idem-ia/idem-deployer:v1
```

---

## 🟥 Cas d’utilisation : **GCP**

```bash
docker run --rm -it \
  -v $(pwd)/terraform:/deploy \
  -e CLOUD_PROVIDER=gcp \
  -e TF_REGION=europe-west1 \
  -e TF_BACKEND_BUCKET=tfstate-idem \
  -e TF_BACKEND_KEY=project-x/terraform.tfstate \
  -e TF_FIRST_RUN=true \
  -e GOOGLE_CREDENTIALS="$(cat creds.json)" \
  ghcr.io/idem-ia/idem-deployer:v1
```

---

## 💡 Notes

* `TF_FIRST_RUN=true` : crée le bucket/container nécessaire pour stocker le backend Terraform.
* `TF_FIRST_RUN=false` (ou omis) : suppose que le backend existe déjà.
* Le répertoire `$(pwd)` ou `$(pwd)/terraform` contient les fichiers `.tf`.

---

## 📂 Structure interne attendue

```bash
./main.tf
./variables.tf
./outputs.tf
...
```

---

## 📦 Build de l’image (si besoin)

```bash
docker build -t idem-deployer .
```

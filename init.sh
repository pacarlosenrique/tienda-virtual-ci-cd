# ==============================
# 🚀 CONFIGURACIÓN CI/CD GCP – Wakamayu (versión idempotente definitiva)
# ==============================

# Variables
PROJECT_ID="wakamayu"
REGION="us-central1"
SA_NAME="gh-actions-deployer"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "==> Activando APIs necesarias..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com storage.googleapis.com serviceusage.googleapis.com --project $PROJECT_ID

echo "==> Verificando Service Account principal..."
if gcloud iam service-accounts describe "$SA_EMAIL" --project "$PROJECT_ID" >/dev/null 2>&1; then
  echo "✅ Service Account '$SA_EMAIL' ya existe."
else
  echo "🆕 Creando Service Account..."
  gcloud iam service-accounts create $SA_NAME --project $PROJECT_ID
fi

echo "==> Verificando y asignando roles requeridos al Service Account principal..."
declare -a ROLES=(
  "roles/run.admin"
  "roles/iam.serviceAccountUser"
  "roles/cloudbuild.builds.editor"
  "roles/artifactregistry.reader"
  "roles/artifactregistry.writer"
  "roles/storage.admin"
  "roles/logging.viewer"
  "roles/serviceusage.serviceUsageConsumer"
)

for ROLE in "${ROLES[@]}"; do
  if gcloud projects get-iam-policy $PROJECT_ID \
      --flatten="bindings[].members" \
      --format="value(bindings.role)" \
      --filter="bindings.members:serviceAccount:${SA_EMAIL}" \
      | grep -q "$ROLE"; then
    echo "✅ Ya tiene $ROLE"
  else
    echo "➕ Asignando $ROLE ..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:${SA_EMAIL}" \
      --role="$ROLE" >/dev/null
  fi
done

echo "==> Verificando y asignando roles al Service Account interno de Cloud Build..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

declare -a CB_ROLES=(
  "roles/artifactregistry.writer"
  "roles/run.developer"
  "roles/serviceusage.serviceUsageConsumer"
  "roles/logging.viewer"
)

for ROLE in "${CB_ROLES[@]}"; do
  if gcloud projects get-iam-policy $PROJECT_ID \
      --flatten="bindings[].members" \
      --format="value(bindings.role)" \
      --filter="bindings.members:serviceAccount:${CLOUDBUILD_SA}" \
      | grep -q "$ROLE"; then
    echo "✅ Cloud Build SA ya tiene $ROLE"
  else
    echo "➕ Asignando $ROLE a Cloud Build SA ..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:${CLOUDBUILD_SA}" \
      --role="$ROLE" >/dev/null
  fi
done

echo "==> Verificando repositorio 'cloud-run-source-deploy'..."
if ! gcloud artifacts repositories describe cloud-run-source-deploy \
    --location=$REGION --project=$PROJECT_ID >/dev/null 2>&1; then
  echo "🆕 Creando repositorio Artifact Registry..."
  gcloud artifacts repositories create cloud-run-source-deploy \
    --repository-format=DOCKER \
    --location=$REGION \
    --description="Repositorio para despliegues Cloud Run desde código" \
    --project=$PROJECT_ID
else
  echo "✅ Repositorio 'cloud-run-source-deploy' ya existe."
fi

echo "==> Verificando existencia de key.json..."
if [ -f "key.json" ]; then
  echo "⚠️  Ya existe key.json, no se generará una nueva."
else
  echo "🆕 Generando nueva clave del Service Account..."
  gcloud iam service-accounts keys create key.json \
    --iam-account="${SA_EMAIL}" \
    --project=$PROJECT_ID
  echo "✅ key.json generada correctamente."
fi

echo "🎯 Configuración completada con éxito."
echo "👉 Archivo generado (si no existía): key.json (no subir al repo, usar como secret en GitHub)"

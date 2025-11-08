# ==============================
# 🧹 LIMPIEZA / ROLLBACK CI/CD GCP – Wakamayu
# Elimina recursos creados por el setup del pipeline
# ==============================

# Variables
PROJECT_ID="wakamayu"
REGION="us-central1"
SA_NAME="gh-actions-deployer"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
ARTIFACT_REPO="cloud-run-source-deploy"

echo "⚠️  Iniciando limpieza de recursos CI/CD para el proyecto: $PROJECT_ID ($REGION)"
echo "------------------------------------------------------------"

# ==============================
# 1️⃣ Eliminar servicio(s) de Cloud Run
# ==============================
echo "==> Buscando servicios Cloud Run..."
SERVICES=$(gcloud run services list --region=$REGION --project=$PROJECT_ID --format="value(metadata.name)")

if [ -z "$SERVICES" ]; then
  echo "✅ No hay servicios Cloud Run para eliminar."
else
  for SVC in $SERVICES; do
    echo "🗑️  Eliminando servicio Cloud Run: $SVC"
    gcloud run services delete "$SVC" --region=$REGION --project=$PROJECT_ID --quiet
  done
fi

# ==============================
# 2️⃣ Eliminar repositorio de Artifact Registry
# ==============================
echo "==> Verificando repositorio Artifact Registry..."
if gcloud artifacts repositories describe $ARTIFACT_REPO --location=$REGION --project=$PROJECT_ID >/dev/null 2>&1; then
  echo "🗑️  Eliminando repositorio Artifact Registry: $ARTIFACT_REPO"
  gcloud artifacts repositories delete $ARTIFACT_REPO --location=$REGION --project=$PROJECT_ID --quiet
else
  echo "✅ Repositorio Artifact Registry no existe o ya fue eliminado."
fi

# ==============================
# 3️⃣ Eliminar buckets temporales de Cloud Build (si existen)
# ==============================
echo "==> Buscando buckets temporales de Cloud Build..."
BUCKETS=$(gcloud storage buckets list --project=$PROJECT_ID --format="value(name)" | grep "gcp-builds-" || true)
if [ -z "$BUCKETS" ]; then
  echo "✅ No se encontraron buckets temporales de Cloud Build."
else
  for BKT in $BUCKETS; do
    echo "🗑️  Eliminando bucket temporal: $BKT"
    gcloud storage rm -r "gs://$BKT" --quiet || echo "⚠️  No se pudo eliminar: $BKT"
  done
fi

# ==============================
# 4️⃣ Revocar roles del Service Account (opcional)
# ==============================
echo "==> Revocando roles asignados al Service Account principal..."
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
    echo "🔻 Quitando rol $ROLE ..."
    gcloud projects remove-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:${SA_EMAIL}" \
      --role="$ROLE" --quiet
  fi
done

# ==============================
# 5️⃣ Eliminar la cuenta de servicio
# ==============================
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "🗑️  Eliminando Service Account: $SA_EMAIL"
  gcloud iam service-accounts delete "$SA_EMAIL" --project="$PROJECT_ID" --quiet
else
  echo "✅ La cuenta de servicio ya no existe."
fi

# ==============================
# 6️⃣ Eliminar key.json local
# ==============================
if [ -f "key.json" ]; then
  echo "🗑️  Eliminando archivo local key.json..."
  rm -f key.json
else
  echo "✅ No hay archivo key.json local para eliminar."
fi

echo "------------------------------------------------------------"
echo "🎯 Limpieza completada. Todos los recursos del CI/CD fueron eliminados."
echo "👉 Verifica en consola: https://console.cloud.google.com/run?project=$PROJECT_ID"

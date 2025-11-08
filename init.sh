# Variables
PROJECT_ID="wakamayu"
REGION="us-central1"     # o la que quieras (ej. us-east1)
SA_NAME="gh-actions-deployer"

# Activa APIs
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project $PROJECT_ID

# Crea Service Account
gcloud iam service-accounts create $SA_NAME --project $PROJECT_ID

# Permisos mínimos
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"

# Genera key JSON (guardará key.json en tu carpeta actual)
gcloud iam service-accounts keys create key.json \
  --iam-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project $PROJECT_ID

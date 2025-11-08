# 🚀 CI/CD Automatizado con GitHub Actions y Google Cloud Run

![Pipeline](docs/diagram-cicd-[PROJECT].png)

---

## 📘 Descripción general

Este proyecto implementa una arquitectura **CI/CD (Integración y Despliegue Continuo)** utilizando  
**GitHub Actions** y **Google Cloud Platform (GCP)** para automatizar el ciclo de vida de despliegue de una aplicación Node.js.

El pipeline compila, versiona y despliega el servicio **serverless** en **Cloud Run**, gestionando imágenes y permisos de forma segura mediante **Service Accounts** e **IAM Roles**.

---

## 🧠 Arquitectura de componentes

**Flujo principal:**
1. **GitHub Actions** detecta un `push` en la rama `main`.
2. El workflow autentica con GCP usando la **Service Account** `gh-actions-deployer`.
3. **Cloud Build** genera una imagen usando Buildpacks (sin Dockerfile).
4. **Artifact Registry** almacena la imagen resultante.
5. **Cloud Run** despliega automáticamente la nueva revisión.
6. **Cloud Logging** y **Cloud Storage** registran logs y artefactos temporales.

![Arquitectura](docs/architecture-overview.png)

---

## ⚙️ Servicios involucrados

| Servicio | Función | Costo estimado |
|-----------|----------|----------------|
| **GitHub Actions** | Orquestador CI/CD | Gratuito |
| **Cloud Run** | Entorno serverless de ejecución | Bajo (por uso) |
| **Cloud Build** | Compilación automática con Buildpacks | Gratuito hasta 120 min/mes |
| **Artifact Registry** | Repositorio de imágenes | $0.03/GB/mes |
| **Cloud Storage** | Fuente temporal durante el build | $0 |
| **Cloud Logging** | Logs de build y ejecución | Gratuito (hasta cuota base) |

---

## 🔐 Roles IAM y seguridad

### Service Account principal: `gh-actions-deployer@[PROJECT].iam.gserviceaccount.com`

| Rol | Propósito |
|-----|------------|
| `roles/run.admin` | Crear/actualizar servicios Cloud Run |
| `roles/artifactregistry.writer` | Escribir imágenes en Artifact Registry |
| `roles/cloudbuild.builds.editor` | Ejecutar builds |
| `roles/storage.admin` | Subir código fuente temporal |
| `roles/serviceusage.serviceUsageConsumer` | Usar APIs internas GCP |
| `roles/logging.viewer` | Ver logs en Cloud Logging |

### Service Account interno de Cloud Build:
`<PROJECT_NUMBER>@cloudbuild.gserviceaccount.com`

| Rol | Propósito |
|-----|------------|
| `roles/run.developer` | Desplegar servicios |
| `roles/artifactregistry.writer` | Escribir imágenes |
| `roles/serviceusage.serviceUsageConsumer` | Usar APIs internas |

---

## 🧰 Scripts incluidos

### 📄 `setup-[PROJECT].sh`
Configura automáticamente el entorno CI/CD en GCP:
- Crea el **Service Account**.  
- Asigna los roles necesarios.  
- Crea el **Artifact Registry**.  
- Genera la key `key.json` (para usar como Secret en GitHub).

### 📄 `cleanup-[PROJECT].sh`
Desinstala los recursos del entorno:
- Elimina servicios de Cloud Run y repositorios Artifact Registry.  
- Limpia buckets temporales.  
- Revoca roles.  
- (Opcional) Elimina la Service Account y `key.json`.

---

## 🧩 Estructura del repositorio

```bash
.
├── .github/
│   └── workflows/
│       └── ci-cd-cloudrun.yml     # Pipeline GitHub Actions
├── docs/
│   ├── diagram-cicd-[PROJECT].png  # Diagrama de componentes
│   └── architecture-overview.png  # Diagrama arquitectónico
├── server.js                      # App Node.js simple
├── package.json                   # Dependencias del proyecto
├── setup-[PROJECT].sh              # Script de configuración GCP
├── cleanup-[PROJECT].sh            # Script de limpieza GCP
└── README.md

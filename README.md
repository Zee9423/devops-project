# FastAPI on AKS — Containerized REST API with full CI/CD

A small Python **FastAPI** service deployed to **Azure Kubernetes Service
(AKS)**, with infrastructure provisioned by **Terraform** (remote state),
shipped by a **GitHub Actions** pipeline that authenticates to Azure with
**OIDC (no stored secrets)** and enforces **test + security quality gates**.

The application is intentionally tiny. The focus of this project is the
**delivery pipeline, infrastructure, and production practices** around it.

## Architecture

```
 push to main
      │
      ▼
┌─────────────────────── GitHub Actions ───────────────────────┐
│ quality gates:  pytest · terraform fmt/validate · tflint      │  ← blocks bad code
│      │ (pass)                                                 │
│      ▼                                                         │
│ OIDC login to Azure (federated identity — no secrets)         │
│      ▼                                                         │
│ terraform apply ─► RG + ACR + AKS  (state in Azure Blob)      │
│      ▼                                                         │
│ docker build ─► Trivy scan (fail on HIGH/CRITICAL) ─► push ACR │  ← blocks vulns
│      ▼                                                         │
│ kubectl apply ─► AKS (2 replicas, probes, LoadBalancer)       │
└───────────────────────────────────────────────────────────────┘
      │
      ▼
  public IP  ──►  GET /hello  ──►  load-balanced across pods
```

## Tech stack

| Layer          | Tool                                                       |
|----------------|------------------------------------------------------------|
| App            | Python FastAPI (`/health`, `/hello`)                       |
| Containers     | Docker (slim base, non-root, OS-patched, HEALTHCHECK)      |
| Registry       | Azure Container Registry (ACR, private)                    |
| Infrastructure | Terraform — remote state in Azure Blob + state locking     |
| Orchestration  | Kubernetes on AKS (Deployment + Service, liveness/readiness)|
| CI/CD          | GitHub Actions, OIDC auth, quality + security gates        |

## Endpoints

| Method | Path      | Description                                                |
|--------|-----------|------------------------------------------------------------|
| GET    | `/health` | Health check — target of the K8s liveness/readiness probes |
| GET    | `/hello`  | Greeting; `?name=` optional; `served_by` = Pod name        |

`served_by` returns the serving Pod's name, so repeated calls visibly show
Kubernetes load-balancing across replicas.

## Design decisions (the "why")

- **Tiny app on purpose.** The value here is infrastructure and delivery, not
  app features. A trivial payload keeps the focus on the pipeline.
- **Pinned dependency & image versions** → reproducible builds.
- **Layer-cached Dockerfile** (deps before app copy) → fast CI rebuilds.
  **Non-root user** and **OS package patching** → passes security scanning and
  AKS security expectations.
- **Terraform remote state in Azure Blob** with lease-based **locking** — state
  survives the machine, CI and humans share one source of truth, and two
  applies can't corrupt it. The state storage is bootstrapped out-of-band with
  the Azure CLI (it must exist before Terraform can use it).
- **Managed identity over secrets.** AKS pulls from ACR via an `AcrPull` role
  on the cluster identity — no registry passwords anywhere.
- **OIDC for CI.** GitHub Actions exchanges a short-lived token for Azure
  access via a federated credential — no client secret stored anywhere.
- **Quality + security gates.** Unit tests, Terraform `fmt`/`validate`/`tflint`,
  and a Trivy image scan that **fails the build on HIGH/CRITICAL** — bad code
  or vulnerable images never reach the cluster.
- **Immutable image tags** = git commit SHA, so every deployment traces back
  to an exact commit.

## Possible next steps

Centralized observability (Container Insights + Azure Monitor + alerts),
Horizontal Pod Autoscaler, multi-environment promotion, branch protection
requiring the checks, and supply-chain hardening (image signing, SBOM).

## Run locally

```bash
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
pytest -q                       # run the tests
uvicorn app.main:app --reload   # http://127.0.0.1:8000/docs
```

## Provision / tear down

```bash
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve
terraform -chdir=terraform destroy -auto-approve
```

Normally you don't run these by hand — pushing to `main` makes the pipeline
provision and deploy automatically. Documentation-only changes are excluded
from the pipeline so they don't rebuild infrastructure.

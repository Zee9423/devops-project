"""FastAPI on AKS — demo API.

A deliberately small FastAPI service. The point of this project is the
delivery pipeline around it (Docker -> ACR -> AKS via Terraform + GitHub
Actions), not the app itself, so the endpoints are intentionally minimal.
"""

import socket

from fastapi import FastAPI

app = FastAPI(
    title="FastAPI on AKS Demo API",
    description="Containerized REST API deployed to AKS with full CI/CD.",
    version="1.0.0",
)


@app.get("/health")
def health():
    """Liveness/readiness probe target used by the Kubernetes deployment."""
    return {"status": "ok"}


@app.get("/hello")
def hello(name: str = "world"):
    """Trivial endpoint to prove the app is reachable end-to-end.

    `served_by` is the container hostname, which in Kubernetes is the Pod
    name. Calling this repeatedly shows the value changing as the Service
    load-balances across Pods — a live, visible proof of the K8s setup.
    """
    return {"message": f"Hello, {name}!", "served_by": socket.gethostname()}

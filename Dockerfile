# --- Base image -------------------------------------------------------------
# python:3.12-slim: a stable, well-supported Python with a minimal Debian base.
# "slim" keeps the image small (smaller = faster pulls in CI/AKS, less attack
# surface). We pin the minor version for reproducible builds.
FROM python:3.12-slim

# --- Python runtime behaviour ----------------------------------------------
# PYTHONDONTWRITEBYTECODE: don't write .pyc files (pointless in a container).
# PYTHONUNBUFFERED: stream stdout/stderr straight to the logs so `kubectl logs`
# and `docker logs` show output immediately instead of buffering it.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Patch OS packages in the base image. Base images ship with known-CVE Debian
# packages over time; upgrading clears them so the Trivy security gate passes.
# Own layer + cleaned apt lists keeps the image small and the layer cacheable.
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# All subsequent commands run from /app inside the image.
WORKDIR /app

# --- Dependency layer (cached) ---------------------------------------------
# Copy ONLY requirements first and install. Docker caches layers; as long as
# requirements.txt is unchanged, rebuilds skip re-installing deps even when
# app code changes. This makes the CI build (Phase 5) much faster.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Application code ------------------------------------------------------
COPY app ./app

# --- Run as a non-root user (security best practice) -----------------------
# If the container is compromised, the attacker is an unprivileged user, not
# root. Kubernetes/AKS security policies often reject containers that run as
# root, so this also keeps us deployable.
RUN useradd --create-home appuser
USER appuser

# Documents the port the app listens on (informational; the actual mapping
# happens at `docker run -p` / the Kubernetes Service in Phase 4).
EXPOSE 8000

# --- Container-level healthcheck -------------------------------------------
# Hits the same /health endpoint Kubernetes will probe in Phase 4. Lets Docker
# report the container as healthy/unhealthy locally before we get to AKS.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0) if urllib.request.urlopen('http://127.0.0.1:8000/health').status==200 else sys.exit(1)"

# --- Start the server ------------------------------------------------------
# Bind 0.0.0.0 so the server is reachable from outside the container (127.0.0.1
# would only be reachable from inside it). No --reload: that's a dev-only flag.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

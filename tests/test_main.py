"""Unit tests for the API.

These run as a CI quality gate: if any assertion fails, the pipeline stops
and nothing is deployed. Small but real — they prove the endpoints' contract.
"""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_returns_ok():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_hello_defaults_to_world():
    resp = client.get("/hello")
    assert resp.status_code == 200
    body = resp.json()
    assert body["message"] == "Hello, world!"
    # served_by is the pod/host name — just assert it's present and non-empty.
    assert body["served_by"]


def test_hello_uses_name_query_param():
    resp = client.get("/hello", params={"name": "Ziad"})
    assert resp.status_code == 200
    assert resp.json()["message"] == "Hello, Ziad!"

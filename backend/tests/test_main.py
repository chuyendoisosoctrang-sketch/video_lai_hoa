from fastapi.testclient import TestClient
from main import app
from security import license_manager
import time

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "message": "Video Tuyên Truyền Lai Hòa API is running"}

def test_generate_video_without_license():
    response = client.post("/generate-video", json={"topic": "Test topic"})
    assert response.status_code == 422 # Missing header

def test_generate_video_with_invalid_license():
    response = client.post("/generate-video", json={"topic": "Test topic"}, headers={"x-license-key": "invalid_key"})
    assert response.status_code == 403

def test_generate_video_with_valid_license(monkeypatch):
    # Mock time tampering to always return False
    import security
    monkeypatch.setattr(security, "check_time_tampering", lambda: False)
    
    valid_key = license_manager.generate_license(days_valid=1)
    response = client.post("/generate-video", json={"topic": "Test topic"}, headers={"x-license-key": valid_key})
    assert response.status_code == 200
    assert response.json()["status"] == "success"

def test_generate_video_with_expired_license(monkeypatch):
    import security
    monkeypatch.setattr(security, "check_time_tampering", lambda: False)
    
    # Generate an expired key
    expired_key = license_manager.generate_license(days_valid=-1)
    response = client.post("/generate-video", json={"topic": "Test topic"}, headers={"x-license-key": expired_key})
    assert response.status_code == 403

import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from app import app

def test_home():
    client = app.test_client()
    response = client.get("/")

    assert response.status_code == 200
    assert b"CI/CD Portfolio Project is running!" in response.data

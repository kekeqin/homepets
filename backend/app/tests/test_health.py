from fastapi.testclient import TestClient


def test_health_check(client: TestClient) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_privacy_policy_page(client: TestClient) -> None:
    response = client.get("/privacy.html")
    assert response.status_code == 200
    assert "text/html" in response.headers.get("content-type", "")
    body = response.text
    assert "拾星小宠隐私政策" in body
    assert "我们不会出售您的个人信息" in body
    assert "support@kkqin.com" in body


def test_terms_of_service_page(client: TestClient) -> None:
    response = client.get("/terms.html")
    assert response.status_code == 200
    assert "text/html" in response.headers.get("content-type", "")
    body = response.text
    assert "拾星小宠用户协议" in body
    assert "试用与订阅" in body or "试用、订阅" in body
    assert "support@kkqin.com" in body


def test_site_styles_available(client: TestClient) -> None:
    response = client.get("/styles.css")
    assert response.status_code == 200
    assert "text/css" in response.headers.get("content-type", "")

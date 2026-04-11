import http.client
import json

conn = http.client.HTTPConnection("127.0.0.1", 8000, timeout=10)

data = json.dumps({"phone": "13800138000", "password": "123456"})

print("Testing login API...")

try:
    conn.request("POST", "/api/auth/login", data, {"Content-Type": "application/json"})
    response = conn.getresponse()
    print(f"Status: {response.status}")
    print(f"Response: {response.read().decode()}")
except Exception as e:
    print(f"Error: {e}")
finally:
    conn.close()

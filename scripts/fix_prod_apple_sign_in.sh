#!/usr/bin/env bash
set -euo pipefail

COMPOSE_DIR="${COMPOSE_DIR:-/root/pickstarpet}"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
BACKUP_FILE="$COMPOSE_FILE.bak.apple-$(date +%Y%m%d%H%M%S)"

cd "$COMPOSE_DIR"
cp "$COMPOSE_FILE" "$BACKUP_FILE"
echo "Backed up compose to $BACKUP_FILE"

python3 - <<'PY'
from pathlib import Path

path = Path("/root/pickstarpet/docker-compose.yml")
text = path.read_text(encoding="utf-8")
if "APPLE_SIGN_IN_CLIENT_IDS" in text and "com.kkqin.pickstarpet" in text:
    print("Apple env already configured correctly")
else:
    # Remove any broken partial Apple lines first.
    lines = []
    for line in text.splitlines(keepends=True):
        if "APPLE_SIGN_IN_" in line:
            continue
        lines.append(line)
    text = "".join(lines)

    anchor = (
        "      SMS_VERIFY_FAILURE_WINDOW_SECONDS: "
        "${SMS_VERIFY_FAILURE_WINDOW_SECONDS:-600}\n"
    )
    insert = (
        anchor
        + "      APPLE_SIGN_IN_CLIENT_IDS: ${APPLE_SIGN_IN_CLIENT_IDS:-com.kkqin.pickstarpet}\n"
        + "      APPLE_SIGN_IN_KEYS_URL: ${APPLE_SIGN_IN_KEYS_URL:-https://appleid.apple.com/auth/keys}\n"
        + "      APPLE_SIGN_IN_TIMEOUT_SECONDS: ${APPLE_SIGN_IN_TIMEOUT_SECONDS:-5}\n"
        + "      APPLE_SIGN_IN_KEYS_CACHE_SECONDS: ${APPLE_SIGN_IN_KEYS_CACHE_SECONDS:-3600}\n"
    )
    if anchor not in text:
        raise SystemExit(f"anchor not found in {path}")
    path.write_text(text.replace(anchor, insert, 1), encoding="utf-8")
    print("Inserted Apple Sign In environment variables")
PY

echo "---- compose apple lines ----"
grep -n APPLE_SIGN_IN "$COMPOSE_FILE" || true

echo "---- recreate backend ----"
docker compose up -d backend
sleep 5
docker compose ps

echo "---- backend apple env ----"
docker inspect homepets-backend-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep APPLE || true

echo "---- local apple endpoint probe ----"
status=$(curl -s -o /tmp/apple_resp.txt -w '%{http_code}' \
  -X POST http://127.0.0.1:8000/api/auth/apple \
  -H 'Content-Type: application/json' \
  -d '{"identity_token":"test","authorization_code":"test"}')
echo "HTTP $status"
cat /tmp/apple_resp.txt
echo

if [ "$status" = "503" ]; then
  echo "FAIL: still returning 503 (Apple Sign In not configured)"
  exit 1
fi

if [ "$status" = "401" ] || [ "$status" = "422" ]; then
  echo "OK: Apple endpoint is configured (invalid test token rejected as expected)"
  exit 0
fi

echo "Unexpected status: $status"
exit 1

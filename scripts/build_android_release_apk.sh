#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
APP_DIR="$REPO_ROOT/app"

API_BASE_URL="${API_BASE_URL:-https://pickstarpet.kkqin.com}"

case "$API_BASE_URL" in
  http://10.0.2.2:*|http://127.0.0.1:*|http://localhost:*|http://192.168.*|*homepets.example.com*)
    echo "API_BASE_URL must not point to a local development server: $API_BASE_URL" >&2
    exit 1
    ;;
esac

REVENUECAT_ANDROID_API_KEY="${REVENUECAT_ANDROID_API_KEY:-}"
REVENUECAT_ENTITLEMENT_ID="${REVENUECAT_ENTITLEMENT_ID:-premium}"
REVENUECAT_USE_TEST_STORE="${REVENUECAT_USE_TEST_STORE:-false}"

cd "$APP_DIR"

flutter build apk --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=REVENUECAT_ANDROID_API_KEY="$REVENUECAT_ANDROID_API_KEY" \
  --dart-define=REVENUECAT_ENTITLEMENT_ID="$REVENUECAT_ENTITLEMENT_ID" \
  --dart-define=REVENUECAT_USE_TEST_STORE="$REVENUECAT_USE_TEST_STORE" \
  "$@"
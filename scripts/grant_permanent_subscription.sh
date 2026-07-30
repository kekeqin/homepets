#!/usr/bin/env bash
# Grant permanent premium subscription to a user on the production server.
#
# Connects over SSH, runs the Python admin script inside the backend Docker container.
#
# Usage:
#   ./scripts/grant_permanent_subscription.sh ABC234
#   ./scripts/grant_permanent_subscription.sh --public-id ABC234
#   ./scripts/grant_permanent_subscription.sh --user-id 42 --dry-run
#   SSH_HOST=root@example.com ./scripts/grant_permanent_subscription.sh ABC234
#
# Positional argument is public_id by default (not internal users.id).
#
# Env overrides:
#   SSH_HOST      default: root@kkqin.com
#   COMPOSE_DIR   default: /root/pickstarpet
#   COMPOSE_SERVICE default: backend

set -euo pipefail

SSH_HOST="${SSH_HOST:-root@kkqin.com}"
COMPOSE_DIR="${COMPOSE_DIR:-/root/pickstarpet}"
COMPOSE_SERVICE="${COMPOSE_SERVICE:-backend}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/grant_permanent_subscription.py"

if [[ ! -f "$PY_SCRIPT" ]]; then
  echo "ERROR: Python script not found: $PY_SCRIPT" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  cat <<'EOF' >&2
Usage:
  grant_permanent_subscription.sh <public_id>
  grant_permanent_subscription.sh --public-id <public_id>
  grant_permanent_subscription.sh --user-id <internal_id>
  grant_permanent_subscription.sh ... --dry-run

Examples:
  ./scripts/grant_permanent_subscription.sh ABC234
  ./scripts/grant_permanent_subscription.sh --public-id ABC234
  ./scripts/grant_permanent_subscription.sh ABC234 --dry-run
  ./scripts/grant_permanent_subscription.sh --user-id 42
EOF
  exit 1
fi

echo "==> SSH host:        $SSH_HOST"
echo "==> Compose dir:     $COMPOSE_DIR"
echo "==> Compose service: $COMPOSE_SERVICE"
echo "==> Args:            $*"
echo "==> Piping $PY_SCRIPT into container python"

# Quote each arg for the remote shell (user ids / flags are simple; still be safe).
remote_args=""
for arg in "$@"; do
  remote_args+=" $(printf '%q' "$arg")"
done

# -T: disable pseudo-tty so stdin is the script body
# `python -` reads the program from stdin; remaining args are forwarded to the script.
# shellcheck disable=SC2029
ssh "$SSH_HOST" \
  "cd $(printf '%q' "$COMPOSE_DIR") && docker compose exec -T $(printf '%q' "$COMPOSE_SERVICE") python -${remote_args}" \
  < "$PY_SCRIPT"

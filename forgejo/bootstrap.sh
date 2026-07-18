#!/bin/bash

set -euo pipefail

# Usage: ./bootstrap.sh <username> <password> <email> <orgname> [gitreposdir]
if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
  echo "Usage: $0 <username> <password> <email> <orgname> [gitreposdir]"
  exit 1
fi

USERNAME="$1"
PASSWORD="$2"
EMAIL="$3"
ORGNAME="$4"
GITREPOSDIR="${5:-$HOME/git/sandbox-local}"

NAMESPACE="${NAMESPACE:-forgejo}"
POD_SELECTOR="${POD_SELECTOR:-app.kubernetes.io/name=forgejo}"
CONTAINER_NAME="${CONTAINER_NAME:-forgejo}"
FORGEJO_URL="${FORGEJO_URL:-http://localhost:3000}"
FORGEJO_URL="${FORGEJO_URL%/}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd kubectl
require_cmd curl
require_cmd git

# Get Forgejo pod name.
pod=$(kubectl -n "$NAMESPACE" get pod -l "$POD_SELECTOR" -o jsonpath="{.items[0].metadata.name}")

if [ -z "$pod" ]; then
  echo "No Forgejo pod found in namespace '$NAMESPACE' with selector '$POD_SELECTOR'." >&2
  exit 1
fi

exec_forgejo() {
  kubectl -n "$NAMESPACE" exec "$pod" -c "$CONTAINER_NAME" -- forgejo "$@"
}

# Check if user exists.
if exec_forgejo admin user list | tail -n +2 | tr -s ' ' | cut -d ' ' -f 2 | grep -Fxq "$USERNAME"; then
  echo "User '$USERNAME' already exists, updating password."
  exec_forgejo admin user change-password --username "$USERNAME" --password "$PASSWORD"
else
  exec_forgejo admin user create --username "$USERNAME" --password "$PASSWORD" --email "$EMAIL" --must-change-password=false
fi

# Create random token name.
TOKEN_NAME="access-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"

# Create token using raw output for reliable scripting.
token=$(exec_forgejo admin user generate-access-token --username "$USERNAME" --token-name "$TOKEN_NAME" --raw)
echo "Forgejo Access Token: $token (token name: $TOKEN_NAME)"

# Check if organization exists.
ORG_CHECK_URL="$FORGEJO_URL/api/v1/orgs/$ORGNAME"
org_status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $token" "$ORG_CHECK_URL")
if [ "$org_status" -eq 200 ]; then
  echo "Organization '$ORGNAME' already exists, skipping creation."
else
  echo "[INFO] Creating organization '$ORGNAME' via API..."
  curl -fsS -X POST "$FORGEJO_URL/api/v1/orgs" \
    -H "accept: application/json" \
    -H "Authorization: token $token" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"$ORGNAME\", \"description\": \"Testorg\"}"
  printf '\n'
fi

# Only import repositories if gitreposdir is specified as input.
if [ "$#" -eq 5 ]; then
  for repo_path in "$GITREPOSDIR"/*; do
    [ -d "$repo_path" ] || continue

    repo=$(basename "$repo_path")
    echo "$repo"

    curl -fsS -X POST "$FORGEJO_URL/api/v1/user/repos" \
      -H "accept: application/json" \
      -H "Authorization: token $token" \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"$repo\"}"
    printf '\n'

    curl -fsS -X POST "$FORGEJO_URL/api/v1/repos/$USERNAME/$repo/transfer" \
      -H "accept: application/json" \
      -H "Authorization: token $token" \
      -H "Content-Type: application/json" \
      -d "{\"new_owner\": \"$ORGNAME\"}"
    printf '\n'

    push_url="${FORGEJO_URL/http:\/\//http://$USERNAME:$token@}"
    push_url="${push_url/https:\/\//https://$USERNAME:$token@}"

    echo "git -C $repo_path push $push_url/$ORGNAME/$repo.git"
    git -C "$repo_path" push "$push_url/$ORGNAME/$repo.git" --all
  done
fi

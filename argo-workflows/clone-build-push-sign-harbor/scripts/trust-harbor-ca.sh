#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  printf 'usage: %s <harbor-namespace> <harbor-ca-secret>\n' "$0" >&2
  exit 1
fi

HARBOR_NAMESPACE="$1"
HARBOR_CA_SECRET="$2"

TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

CA_FILE="$TMP_DIR/harbor-ca.crt"

kubectl -n "$HARBOR_NAMESPACE" get secret "$HARBOR_CA_SECRET" -o jsonpath="{.data['ca\.crt']}" | base64 -d > "$CA_FILE"

if [ ! -s "$CA_FILE" ]; then
  printf 'failed to extract Harbor CA from secret %s/%s\n' "$HARBOR_NAMESPACE" "$HARBOR_CA_SECRET" >&2
  exit 1
fi

NODE_NAMES=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

if [ -z "$NODE_NAMES" ]; then
  printf 'no vcluster nodes found in current kubectl context\n' >&2
  exit 1
fi

for node in $NODE_NAMES; do
  container_name="$node"
  if ! docker inspect "$container_name" >/dev/null 2>&1; then
    container_name="vcluster.cp.$node"
  fi

  docker inspect "$container_name" >/dev/null 2>&1

  docker cp "$CA_FILE" "$container_name:/usr/local/share/ca-certificates/harbor-ca.crt"
  docker exec "$container_name" update-ca-certificates

  docker exec "$container_name" sh -lc '
    if command -v systemctl >/dev/null 2>&1; then
      systemctl restart containerd || systemctl restart k3s || systemctl restart k3s-agent
    elif command -v service >/dev/null 2>&1; then
      service containerd restart || service k3s restart || service k3s-agent restart
    else
      printf "no supported service manager found to restart container runtime\n" >&2
      exit 1
    fi
  '
done

#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  printf 'usage: %s <kube-context> <harbor-namespace> <harbor-ca-secret>\n' "$0" >&2
  exit 1
fi

KUBE_CONTEXT="$1"
HARBOR_NAMESPACE="$2"
HARBOR_CA_SECRET="$3"

TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

CA_FILE="$TMP_DIR/harbor-ca.crt"

kubectl --context "$KUBE_CONTEXT" -n "$HARBOR_NAMESPACE" get secret "$HARBOR_CA_SECRET" -o jsonpath="{.data['ca\.crt']}" | base64 -d > "$CA_FILE"

if [ ! -s "$CA_FILE" ]; then
  printf 'failed to extract Harbor CA from secret %s/%s\n' "$HARBOR_NAMESPACE" "$HARBOR_CA_SECRET" >&2
  exit 1
fi

NODE_NAMES=$(kubectl --context "$KUBE_CONTEXT" get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

if [ -z "$NODE_NAMES" ]; then
  printf 'no vcluster nodes found for context %s\n' "$KUBE_CONTEXT" >&2
  exit 1
fi

for node in $NODE_NAMES; do
  docker inspect "$node" >/dev/null 2>&1

  docker cp "$CA_FILE" "$node:/usr/local/share/ca-certificates/harbor-ca.crt"
  docker exec "$node" update-ca-certificates

  docker exec "$node" sh -lc '
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

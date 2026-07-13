#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  printf 'usage: %s <app-namespace> <app-name> <timeout-seconds>\n' "$0" >&2
  exit 1
fi

APP_NAMESPACE="$1"
APP_NAME="$2"
TIMEOUT_SECONDS="$3"

end=$((SECONDS + TIMEOUT_SECONDS))

while [ $SECONDS -lt $end ]; do
  sync_status=$(kubectl get application "$APP_NAME" -n "$APP_NAMESPACE" -o jsonpath='{.status.sync.status}' 2>/dev/null | tr -d '[:space:]' || true)
  health_status=$(kubectl get application "$APP_NAME" -n "$APP_NAMESPACE" -o jsonpath='{.status.health.status}' 2>/dev/null | tr -d '[:space:]' || true)

  if [ "$sync_status" = "Synced" ] && [ "$health_status" = "Healthy" ]; then
    exit 0
  fi

  sleep 5
done

kubectl get application "$APP_NAME" -n "$APP_NAMESPACE" -o yaml
exit 1

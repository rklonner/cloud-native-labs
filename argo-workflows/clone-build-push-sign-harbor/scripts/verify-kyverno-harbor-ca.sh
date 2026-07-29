#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  printf 'usage: %s <kyverno-namespace> <harbor-host>\n' "$0" >&2
  exit 1
fi

KYVERNO_NAMESPACE="$1"
HARBOR_HOST="$2"
POD_NAME="harbor-ca-check"

cleanup() {
  kubectl delete pod "$POD_NAME" -n "$KYVERNO_NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
}
trap cleanup EXIT

kubectl delete pod "$POD_NAME" -n "$KYVERNO_NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  namespace: ${KYVERNO_NAMESPACE}
spec:
  restartPolicy: Never
  containers:
    - name: check
      image: curlimages/curl:8.13.0
      command:
        - sh
        - -ec
        - |
          status=$(curl --output /dev/null --silent --show-error --write-out '%{http_code}' https://${HARBOR_HOST}/v2/)
          [ "$status" = "200" ] || [ "$status" = "401" ]
      volumeMounts:
        - name: ca-certificates
          mountPath: /etc/ssl/certs/ca-certificates.crt
          readOnly: true
  volumes:
    - name: ca-certificates
      hostPath:
        path: /etc/ssl/certs/ca-certificates.crt
        type: File
EOF

for i in $(seq 1 12); do
  phase=$(kubectl get pod "$POD_NAME" -n "$KYVERNO_NAMESPACE" -o jsonpath='{.status.phase}')
  case "$phase" in
    Succeeded)
      exit 0
      ;;
    Failed)
      kubectl logs "$POD_NAME" -n "$KYVERNO_NAMESPACE" || true
      kubectl describe pod "$POD_NAME" -n "$KYVERNO_NAMESPACE" || true
      exit 1
      ;;
  esac
  sleep 2
done

kubectl logs "$POD_NAME" -n "$KYVERNO_NAMESPACE" || true
kubectl describe pod "$POD_NAME" -n "$KYVERNO_NAMESPACE" || true
printf 'timed out waiting for Harbor CA verification pod to succeed\n' >&2
exit 1

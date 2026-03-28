# Argo Workflows

## Install helm chart in kind cluster
```bash
# Create kind cluster
kind create cluster

# Switch to kind context
kubectl config use-context kind-kind

# Install
ARGO_WORKFLOWS_VERSION="v4.0.3"
kubectl create namespace argo
kubectl apply --server-side -n argo -f "https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/quick-start-minimal.yaml"

# Fix plugin issue: "artifact driver test not found"
k -n argo edit cm workflow-controller-configmap
# remove artifactrepository "test" and save
k -n argo rollout restart deployment workflow-controller

# Apply additional permissions
kubectl apply -f argo-rbac.yaml

# Verify that Workflows is running
kubectl -n argo get pods --watch

# Install cli (optional)
./cli-install.sh
```

## Usage
```bash
# Port forward Vault server to localhost
kubectl -n argo port-forward service/argo-server 2746:2746

# Access over the Browser
https://localhost:2746/

argo logs @latest
argo logs @latest --follow
```

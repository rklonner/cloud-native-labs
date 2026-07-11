# Kyverno

## Install with helm in kind cluster
```bash
# Create kind cluster
kind create cluster

# Switch to kind context
kubectl config use-context kind-kind

# Add helm repo
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

# Install Kyverno
helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace

# Verify that Kyverno is running
watch kubectl -n kyverno get pods
```

## Usage
```bash
# Verify installed chart
helm list -n kyverno

# Check Kyverno CRDs
kubectl get crd | grep kyverno

# Watch Kyverno admission reports and policies later on
kubectl get clusterpolicy
kubectl get policyreport -A
```

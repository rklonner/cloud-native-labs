# Use WorkflowTemplate to clone public git repo and build an image with buildah

**Demonstrate**:
* How to work with WorkflowTemplate and Workflow
* How to sign images with cosign and upload to Harbor

**Prerequisites**:
* Argo Workflows is setup in your cluster (see [Installation](../Readme.md#install-in-kind-cluster))
* argo CLI is installed (see [Installation](../Readme.md#install-in-kind-cluster))

# Prepare environment
```bash
# Install cosign cli locally
COSIGN_VERSION="3.0.5"
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -L https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${ARCH} -o ./cosign
chmod +x cosign
sudo mv cosign /usr/local/bin

# Create cosign key as kubernetes secret named 'cosign-keys' in namespace'argo'
# Provide a password interactive
cosign generate-key-pair k8s://argo/cosign-keys

cosign.key: private key (encrypted).
cosign.pub: public key (for verification).
cosign.password: password for private key

kubectl create secret generic cosign-harbor-login \
  --from-literal=username='admin' \
  --from-literal=password='Harbor12345'
```

## Trigger workflow from template
```bash
# Install workflow template
kubectl apply -f workflow-template-clone-build.yaml

# Trigger workflow for Dockerfile within this folder
kubectl create -f workflow-clone-build.yaml

# Watch logs of workflow
argo logs @latest --follow

# Trigger workflow to build an arbitrary image like argo cd diff preview
kubectl create -f workflow-clone-build-argocd-diff-preview.yaml

# Watch logs of workflow
argo logs @latest --follow
```
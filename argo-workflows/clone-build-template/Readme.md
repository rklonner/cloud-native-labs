# Use WorkflowTemplate to clone public git repo and build an image with buildah

**Demonstrate**:
* How to work with WorkflowTemplate and Workflow
* How to clone a public git repo
* How to build an image daemonless with buildah

**Prerequisites**:
* Argo Workflows is setup in your cluster (see [Installation](../Readme.md#install-in-kind-cluster))
* argo CLI is installed (see [Installation](../Readme.md#install-in-kind-cluster))

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
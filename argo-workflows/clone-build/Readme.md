# Clone public git repo and build an image with buildah

**Demonstrate**:
* How to clone a public git repo
* How to build an image daemonless with buildah

**Prerequisites**:
* Argo Workflows is setup in your cluster (see [Installation](../Readme.md#install-in-kind-cluster))
* argo CLI is installed (see [Installation](../Readme.md#install-in-kind-cluster))

## Trigger workflow
```bash
# Trigger workflow
kubectl create -f git-clone-buildah-build.yaml

# Watch logs of workflow
argo logs @latest --follow
```
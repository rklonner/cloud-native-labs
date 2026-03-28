# Clone public git repo and list its contents

**Demonstrate**:
* How to clone a public git repo
* How to access the contents

**Prerequisites**:
* Argo Workflows is setup in your cluster (see [Installation](../Readme.md#install-in-kind-cluster))
* argo CLI is installed (see [Installation](../Readme.md#install-in-kind-cluster))

## Trigger workflow
```bash
# Trigger workflow
kubectl create -f git-clone.yaml

# Watch logs of workflow
argo logs @latest --follow
```
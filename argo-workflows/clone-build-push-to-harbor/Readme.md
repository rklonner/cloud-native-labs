# Use WorkflowTemplate to clone public git repo and build an image with buildah and push to Harbor

**Demonstrate**:
* How to work with WorkflowTemplate and Workflow
* How to clone a public git repo
* How to build an image daemonless with buildah
* How to push the built image to Harbor

**Prerequisites**:
* Argo Workflows is setup in your cluster (see [Installation](../Readme.md#install-in-kind-cluster))
* argo CLI is installed (see [Installation](../Readme.md#install-in-kind-cluster))
* Harbor is installed for usage as cluster internal registry (see [Installation](../../harbor/cluster-internal-registry/Readme.md))

## Prepare environment

```bash
# Deploy workflow template
kubectl apply -f workflow-template-clone-build.yaml

# Create secret for pushing image to Harbor
kubectl create secret docker-registry harbor-creds \
  --docker-server=harbor.harbor.svc.cluster.local \
  --docker-username=admin \
  --docker-password=Harbor12345
```

# Trigger a workflow

```bash
# Trigger workflow for Dockerfile within this folder
kubectl create -f workflow-clone-build.yaml

# Watch logs of workflow
argo logs @latest --follow

# Verify in the Harbor UI that the image is uploaded

# Trigger workflow to build an arbitrary image like argo cd diff preview
kubectl create -f workflow-clone-build-argocd-diff-preview.yaml

# Watch logs of workflow
argo logs @latest --follow

# Verify in the Harbor UI that the image is uploaded
```

# Deploy a pod with the new image from Harbor

Kubelet will be able to fetch image if Harbor service and Harbor nginx root CA was configured as described in the Harbor instructions.

```bash
# Deploy pod, it refers to a imagePullSecrets named 'harbor-creds' that is setup during Harbor configuration
kubectl apply -f pod-my-app.yaml

# Check if the pod run successfully and prints out a message
kubectl logs pods/my-app-pod

Output:
Hello World!
```
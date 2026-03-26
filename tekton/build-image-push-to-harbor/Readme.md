# Tekton - Clone public git repo, build image, push to Harbor registry

**Demonstrate**:
* How to install Tekton tasks from local yaml or Tekton catalog
* How to build an image daemonless with buildah
* How to push built image to Harbor

**Prerequisites**:
* Tekton is setup in your cluster (see [Installation](../Readme.md#install-helm-chart-in-kind-cluster))
* Tekton CLI is installed (see [Installation](../Readme.md#install-helm-chart-in-kind-cluster))
* Habor is installed for usage as cluster internal registry (see [Installation](../../harbor/cluster-internal-registry/Readme.md))

## Prepare environment

```bash
# Install custom buildah task and configMap with configuration and git-clone task from catalog
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/refs/heads/main/task/git-clone/0.10/git-clone.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/refs/heads/main/task/buildah/0.9/buildah.yaml

# Deploy our pipeline
kubectl apply -f pipeline-clone-build-push.yaml

# Create secret for pushing image to Harbor
kubectl create secret docker-registry harbor-creds \
  --docker-server=harbor.harbor.svc.cluster.local \
  --docker-username=admin \
  --docker-password=Harbor12345
```

# Trigger a pipeline run

```bash
# We specify the source public git repo and a target image name as input.
kubectl create -f pipelinerun-clone-build-push.yaml

# We can follow the pipeline logs by
tkn pipelinerun logs --last -f
```

# TODO: Deploy pod and let kubelet fetch the image from habor

currently tls issue
```bash
k apply -f pod.yaml

k describe  pods  my-app-pod

  Warning  Failed                           11m (x4 over 13m)     kubelet            spec.containers{my-app}: Failed to
pull image "harbor.harbor.svc.cluster.local/library/my-image:latest": failed to pull and unpack image "harbor.harbor.svc.cluster.local/library/my-image:latest": failed to resolve reference "harbor.harbor.svc.cluster.local/library/my-image:latest": failed to do request: Head "https://harbor.harbor.svc.cluster.local/v2/library/my-image/manifests/latest": net/http: TLS handshake timeout
```
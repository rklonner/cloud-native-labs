# Tekton - Clone public git repo and build image

**Demonstrate**:
* How to install Tekton tasks from local yaml or Tekton catalog
* How to build an image daemonless with buildah
* How to provide config settings for buildah over a configMap

**Prerequisites**:
* Tekton is setup in your cluster (see [Installation](../Readme.md#install-helm-chart-in-kind-cluster))
* Tekton CLI is installed (see [Installation](../Readme.md#install-helm-chart-in-kind-cluster))

## Prepare environment

When building images with buildah's default settings the FROM image definition must be fully qualified:

```bash
tekton buildah [build-image : build-and-push] Error: creating build container: short-name resolution enforced but cannot prompt without a TTY
```

would need to use the fully qualified image name:
```docker
WRONG: FROM node:14
CORRECT: FROM docker.io/library/node:14
```

Buildah is using the setting `short-name-mode="enforcing"` by default. In a Tekton task we can configure this by mounting a configMap. 

The official buildah task is not meant for to load a configmap with buildah configuration. 
Let's build our own task based on the latest [official buildah](
https://raw.githubusercontent.com/tektoncd/catalog/refs/heads/main/task/buildah/0.9/buildah.yaml):

We only add a `volume` and `volumeMount` to load a configMap holding buildah settings.

```bash
# Install custom buildah task and configMap with configuration and git-clone task from catalog
kubectl apply -f task-buildah.yaml
kubectl apply -f configmap-buildah-config.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/refs/heads/main/task/git-clone/0.10/git-clone.yaml

# Deploy our pipeline
kubectl apply -f pipeline-clone-build-push.yaml
```

# Trigger a pipeline run 

```bash
# We specify the source public git repo and a target image name as input.
kubectl create -f pipelinerun-clone-build-push.yaml

# We can follow the pipeline logs by
tkn pipelinerun logs --last -f
```


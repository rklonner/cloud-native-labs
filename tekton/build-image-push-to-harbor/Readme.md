kubectl create secret docker-registry harbor-creds   --docker-server=harbor-core.harbor.svc.cluster.local   --docker-username=admin   --docker-password=Harbor12345   --namespace default

```bash
# Install custom buildah task and configMap with configuration and git-clone task from catalog
kubectl apply -f task-buildah.yaml
kubectl apply -f configmap-buildah-config.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/refs/heads/main/task/git-clone/0.10/git-clone.yaml

# Deploy our pipeline
kubectl apply -f pipeline-clone-build-push.yaml
```
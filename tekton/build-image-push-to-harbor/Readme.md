kubectl create secret docker-registry harbor-creds \
  --docker-server=harbor.harbor.svc.cluster.local \
  --docker-username=admin \
  --docker-password=Harbor12345

```bash
# Install custom buildah task and configMap with configuration and git-clone task from catalog
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/refs/heads/main/task/git-clone/0.10/git-clone.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/refs/heads/main/task/buildah/0.9/buildah.yaml

# Deploy our pipeline
kubectl apply -f pipeline-clone-build-push.yaml
```
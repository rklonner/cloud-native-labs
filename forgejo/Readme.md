# Forgejo

## Prerequisites

- `vcluster`, `kubectl`, and `helm` CLI are installed locally
- Docker is running locally for the Docker-backed vcluster driver

## Install Forgejo with Helm in a vcluster

This setup uses the current Forgejo Helm chart published at `oci://code.forgejo.org/forgejo-helm/forgejo`.

The local `vcluster.yaml` exposes this host port:

- Forgejo UI/API: `http://localhost:3000`

To reach Forgejo directly on `localhost`, both settings are required:

- `vcluster.yaml` must map host port `3000` to the vcluster node port `30080`
- the Forgejo Helm release must expose `service.http` as `NodePort` on `30080`

At the time of writing:

- Latest Forgejo release: `v16.0.0`
- Latest Forgejo Helm chart release: `v17.1.3`

The chart README notes that the chart may lag behind the latest Forgejo app release. To ensure the installation uses the latest Forgejo release, set `image.tag=16.0.0` explicitly.

The chart defaults `image.rootless=true`, so it appends `-rootless` automatically. Do not add the `v` prefix to the image tag.

For this lab, the Helm command also sets the built-in Forgejo admin account explicitly:

- username: `gitea_admin`
- password: `admin`

```bash
# Use the Docker-backed vcluster driver
vcluster use driver docker

# Create the vcluster
vcluster create my-cluster --namespace vcluster-my-cluster -f vcluster.yaml

# Switch kubectl to the vcluster context
kubectl config use-context vcluster-docker_my-cluster

# Install or upgrade Forgejo
helm upgrade --install forgejo oci://code.forgejo.org/forgejo-helm/forgejo \
  --namespace forgejo \
  --create-namespace \
  --set service.http.type=NodePort \
  --set service.http.nodePort=30080 \
  --set gitea.admin.username=gitea_admin \
  --set gitea.admin.password=admin \
  --set image.tag=16.0.0

# Verify that Forgejo is running
watch kubectl -n forgejo get pods
```

If the vcluster already exists, reconnect instead of creating it again:

```bash
vcluster use driver docker
vcluster connect my-cluster --namespace vcluster-my-cluster
kubectl config use-context vcluster-docker_my-cluster
```

If you change `vcluster.yaml` port mappings later, recreate the vcluster so the Docker host port mapping is applied.

## Usage

```bash
# Open Forgejo directly
# http://localhost:3000

# Use Forgejo CLI within pod
pod_name=$(kubectl -n forgejo get pod -l app.kubernetes.io/name=forgejo -o jsonpath="{.items[0].metadata.name}")
kubectl -n forgejo exec -it "$pod_name" -- forgejo admin user list
```

## Notes

- The Helm chart is distributed as an OCI artifact, so no `helm repo add` step is required.
- The default chart configuration uses SQLite and is suitable for local testing.
- For a persistent local install, add a values file with `persistence.enabled=true`.
- For production use, prefer an external PostgreSQL or MySQL database and persistent storage.
- This folder includes a minimal `vcluster.yaml` matching the Docker-backed pattern used in the Argo Workflows lab.
- `http://localhost:3000` only works when both the `vcluster.yaml` host port mapping and the Helm `service.http.type=NodePort` settings are applied.

## Optional values file

If you want to keep the image tag pinned in a values file instead of `--set`:

```yaml
service:
  http:
    type: NodePort
    nodePort: 30080

gitea:
  admin:
    username: gitea_admin
    password: admin

image:
  tag: 16.0.0

persistence:
  enabled: true
```

Install or reapply with:

```bash
helm upgrade --install forgejo oci://code.forgejo.org/forgejo-helm/forgejo \
  --namespace forgejo \
  --create-namespace \
  -f values.yaml
```

## Bootstrap

The script `bootstrap.sh` provided alongside this Readme creates a user account and organization.

The built-in admin user created by Helm for this lab is:

- username: `gitea_admin`
- password: `admin`

Example:

```bash
./bootstrap.sh lab-admin admin me@example.com example-org
```

Import local repositories into the new organization:

```bash
./bootstrap.sh lab-admin admin me@example.com example-org /path/to/local/git/repositories
```

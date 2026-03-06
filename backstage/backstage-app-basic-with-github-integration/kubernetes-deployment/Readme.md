# Kubernetes deployment

```bash
# Prepare kind cluster
kind create cluster --name backstage

# Install Cloud Native PG
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update
helm install cnpg cnpg/cloudnative-pg --namespace cnpg-system --create-namespace

kubectl get pods -n cnpg-system --watch

# Creating Backstage postgres cluster
kubectl create namespace backstage

export POSTGRES_PASSWORD=your_secure_password

kubectl -n backstage create secret generic backstage-db-auth \
  --type=kubernetes.io/basic-auth \
  --from-literal=username=backstage_user \
  --from-literal=password=$POSTGRES_PASSWORD

k apply -f postgres-deployment.yaml

# this can take um to 3 min until the 3 replicas are active
# This should be the end result

kubectl -n backstage get clusters.postgresql.cnpg.io backstage-db --watch

NAME           AGE     INSTANCES   READY   STATUS                     PRIMARY
backstage-db   2m49s   3           3       Cluster in healthy state   backstage-db-1

# Workaround
# Fix backstage user permissions, needs createdb
kubectl exec -it backstage-db-1 -n backstage -- psql -U postgres
ALTER USER backstage_user WITH CREATEDB;
k -n backstage rollout restart deployment backstage

# Redo port forwarding

# Build the backstage image locally
yarn install --immutable
yarn tsc
yarn build:backend
docker image build . -f packages/backend/Dockerfile --tag backstage

# Load the image into the nodes of the kind cluster
kind load docker-image backstage:latest --name backstage

# Verify that image is loaded
docker exec -it backstage-control-plane crictl images | grep backstage

docker.io/library/backstage                     latest               4b80c41f6800e       1.24GB

# Deploy backstage
```bash

export POSTGRES_PASSWORD=your_secure_password

kubectl -n backstage create secret generic backstage-postgres-secrets \
  --from-literal=POSTGRES_HOST=backstage-db-rw.backstage.svc.cluster.local \
  --from-literal=POSTGRES_PORT=5432 \
  --from-literal=POSTGRES_USER=backstage_user \
  --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Create secret for github integration
# GITHUB_TOKEN: backstage auth secret creation from a github access token with org:read and repo permission
kubectl -n backstage create secret generic backstage-secrets \
  --from-literal=GITHUB_TOKEN=<your-github-token> \
  --from-literal=BACKSTAGE_AUTH_GITHUB_CLIENT_ID=<your-client-id> \
  --from-literal=BACKSTAGE_AUTH_GITHUB_CLIENT_SECRET=<your-client-secret>

k apply -f backstage-deployment.yaml
kubectl port-forward --namespace=backstage svc/backstage 7007:80

# Redeploy backstage
k -n backstage rollout restart deployment backstage

# Portforward for local access
kubectl port-forward --namespace=backstage svc/backstage 7007:80

# Open browser at localhost:7007

# Debugging
k -n backstage logs services/backstage

# Test postgres network connection
kubectl -n backstage debug -it pod/backstage-687f4c8f4-bk6wt --image=nicolaka/netshoot --profile=general -- bash
nc -zv backstage-db-rw.backstage 5432

# Test postgres database access
kubectl -n backstage debug -it pods/backstage-687f4c8f4-bk6wt --image=postgres:15 --profile=general -- bash
psql -h backstage-db-rw.backstage.svc.cluster.local -U backstage_user -d backstage_main

# Show env vars
k -n backstage exec -it pods/backstage-687f4c8f4-bk6wt -- printenv
```
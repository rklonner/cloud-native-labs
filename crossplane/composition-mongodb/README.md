# Crossplane - Provision a MongoDB database and users with Terraform Workspace

## Demonstrate

* How to simulate an on-prem MongoDB server locally with Docker Compose
* How to connect a local Docker service to a kind cluster network
* How to configure the Crossplane Terraform provider and a `tf.m.upbound.io/Workspace`
* How to provision a MongoDB database, an RW user, and an optional RO user using a Crossplane v2 namespaced XR flow
* How to let Terraform generate the RW/RO passwords and publish them back into a Kubernetes Secret
* How to keep the root MongoDB admin connection string in a Kubernetes Secret only
* How to publish the generated MongoDB credentials into the Workspace connection secret
* How MongoDB users authenticate against the `admin` database while receiving privileges on the target database

## Prerequisites

* A kind cluster with Crossplane installed
  * See the repository root instructions in [`../Readme.md`](../Readme.md)
* `kubectl`
* `docker` and `docker compose`

## Prepare environment

1. Start the local MongoDB server:

```bash
docker compose up -d
```

2. If your kind cluster cannot reach the container by name yet, connect it to the kind network:

```bash
./scripts/connect-kind-network.sh
```

3. Install the Terraform provider and KCL function:

```bash
kubectl apply -f 1-provider-install.yaml
kubectl wait --for=condition=Healthy provider/provider-terraform -n crossplane-system --timeout=10m
kubectl wait --for=condition=Healthy function/crossplane-contrib-function-kcl -n crossplane-system --timeout=10m
```

The Terraform provider configuration uses the documented MongoDB provider fields:

- `mongodb_host`
- `mongodb_port`
- `mongodb_username`
- `mongodb_password`
- `mongodb_auth_database`

4. Create the Kubernetes Secret used by the lab:

```bash
kubectl apply -f 2-secrets.yaml
```

The lab keeps the root admin connection info in the Crossplane namespace. The ProviderConfig reads it directly from the Secret and injects the MongoDB provider block into every Workspace.

For convenience, remember there are two different MongoDB connection URIs in this lab:

- **From your host machine / MongoDB Compass**:

  ```text
  mongodb://mongo-root:Root!Passw0rd@localhost:27017/admin?authSource=admin
  ```

- **From inside Docker / kind / Crossplane**:

  ```text
  mongodb://mongo-root:Root!Passw0rd@mongodb-test:27017/admin?authSource=admin
  ```

The host URI uses `localhost` because Docker publishes port `27017` to your machine. The in-cluster URI uses `mongodb-test`, which is only resolvable from containers or workloads attached to the same Docker network.

5. Apply the provider configuration, XRD, and composition:

```bash
kubectl apply -f 3-provider-config.yaml
kubectl apply -f 4-xrd.yaml
kubectl apply -f 5-composition.yaml
```

The Terraform module itself lives in `crossplane/composition-mongodb/terraform/main.tf` and is referenced remotely via the GitHub repo URL in the composition.

The composition passes only the database/user parameters through normal Terraform vars. The MongoDB root connection settings are centralized in the ProviderConfig.

## Usage

Crossplane v2 does not support claim names in XRDs, so this lab uses a namespaced composite resource directly. The Workspace is rendered via `tf.m.upbound.io`.

```bash
kubectl apply -f 7-xr.yaml
```

Watch the Workspace reconcile:

```bash
kubectl get mongodatabases.mongodb.example.crossplane.io -A
kubectl get workspaces.tf.m.upbound.io -A
kubectl -n crossplane-system get jobs
```

Check the connection secret created by the Workspace. It should contain generated usernames, passwords, and connection strings:

```bash
kubectl get secret -n default lab-mongodb-mongodb-connection -o yaml
```

Validate the MongoDB state from the local container:

```bash
docker exec -it mongodb-test mongosh "mongodb://mongo-root:Root!Passw0rd@localhost:27017/admin?authSource=admin" --eval 'db.getSiblingDB("labdb").getCollectionNames()'
```

## Debugging

* If the Workspace is stuck, inspect the Crossplane and provider logs:

```bash
kubectl describe workspace -n default lab-mongodb-mongodb
kubectl logs -n crossplane-system deploy/provider-terraform
```

* If the Kubernetes Job fails, inspect the Job pod logs:

```bash
kubectl -n crossplane-system get pods
kubectl -n crossplane-system logs job/<job-name>
```

* If the cluster cannot reach MongoDB, re-run the network helper:

```bash
./scripts/connect-kind-network.sh
```

* If you see `mongosh` authentication errors, verify the Secret contents in `2-secrets.yaml` and make sure the root URI uses `authSource=admin`.

* If the Workspace complains about duplicate Terraform variables, ensure the ProviderConfig does not declare `variable` blocks for values already injected by the ProviderConfig configuration.

## Notes and best-practice corrections

* MongoDB does not persist a database object until data is written to it, so the Terraform module creates a small sentinel collection to materialize the database.
* The RO user is optional. Set `createReadOnlyUser: false` in the XR to skip it.
* The root MongoDB admin connection settings are stored in a Kubernetes Secret, not embedded in the composition or Terraform code.
* User passwords are generated by Terraform with `random_password` and published into the Workspace connection secret.
* The Workspace connection secret now exposes `databaseName`, `rwUsername`, `rwPassword`, `rwConnectionString`, and matching RO keys when enabled.
* MongoDB users authenticate against `admin` and are granted `readWrite` / `read` on the target database.

# Crossplane Capabilities Lab

This lab shows an IDP-style setup where a unified application Helm chart renders:

- a simple application `Deployment` and `Service`
- a Crossplane XR for each declared database, external database access, or secret import capability

Argo CD deploys both the platform API layer and the application layer. The key contract is split between `capabilities.databases` for owned databases, `capabilities.databaseAccess` for access to existing databases that the project does not own, and `capabilities.secretImports` for credentials that already exist in Vault.

## Flow

1. Argo CD syncs the platform resources that install the SQL provider, the KCL function, and the XRD/Composition.
2. Argo CD syncs the unified application Helm chart.
3. The Helm chart renders one `CompositeAppDatabase` XR per owned database, one `CompositeExternalDatabaseAccess` XR per external access request, and one `CompositeAppSecretImport` XR per imported secret.
4. The owned database composition creates:
    - `Database`
    - one `User` per declared role
    - one `Grant` per declared role
    - optional app-facing `Secret` resources for `bindAs.connectionString.envVar`
    - one `PushSecret` per role to publish raw credentials into Vault
    - `Usage` resources to enforce safe teardown order: `Database -> User -> Grant`
5. The external access composition creates:
    - one `User` per declared role
    - one `Grant` per declared role
    - optional app-facing `Secret` resources for `bindAs.connectionString.envVar`
    - one `PushSecret` per role to publish raw credentials into Vault
    - `Usage` resources to enforce safe teardown order: `User -> Grant`
6. The secret import composition creates:
    - one or two `ExternalSecret` resources that pull an existing secret from Vault
    - optional env-var remapping for imported `username` and `password` fields

## Important values

The application chart uses this shape:

```yaml
capabilities:
  databases:
    - name: orders
      providerConfigRef: mssql-local
      roles:
        - name: app
          profile: readWrite
          bindAs:
            connectionString:
              envVar: DATABASE_URL
        - name: reporting
          profile: readOnly
          bindAs:
            connectionString:
              envVar: REPORTING_DATABASE_URL
  databaseAccess:
    - name: finance-ro
      providerConfigRef: finance-shared-sql
      target:
        databaseName: finance
      roles:
        - name: reporting
          profile: readOnly
          bindAs:
            connectionString:
              envVar: FINANCE_DATABASE_URL
  secretImports:
    - name: sap-api
      source:
        vault:
          path: orders-api/external/sap-api
          secretStoreRef: vault-app-backend
      bindAs:
        usernamePassword:
          envVars:
            username: SAP_API_USERNAME
            password: SAP_API_PASSWORD
    - name: license
      source:
        vault:
          path: orders-api/external/license
          secretStoreRef: vault-app-backend
      bindAs:
        secretName: orders-api-license
```

Supported role profiles in this lab:

- `readWrite`
- `readOnly`

If a new role with profile `readOnly` is added later and Argo CD syncs again, Crossplane reconciles the XR and creates the extra user and grant for the same target database.

If `bindAs.connectionString.envVar` is set, the composition also creates an app-facing Kubernetes `Secret` with a `connectionString` key, and the Deployment maps that value into the requested env var.

For credentials created by Crossplane, the lab also publishes the raw provider secret into Vault with an automatically derived path:

- owned databases: `projects/<app>/databases/<database>/<role>`
- external database access: `projects/<app>/database-access/<access>/<role>`

Examples:

- `projects/<app>/databases/<database>/app`
- `projects/<app>/databases/<database>/reporting`
- `projects/<app>/database-access/<access>/reporting`

If `capabilities.secretImports` is used, the platform does not create any credentials. It only creates `ExternalSecret` resources so ESO can pull the existing Vault data into Kubernetes secrets for the application namespace.

By default, the secret import composition looks for a cluster-scoped `ClusterSecretStore` called `vault-app-backend`, but each import can override that with `source.vault.secretStoreRef`.

The MSSQL provider needs these `Usage` resources for reliable deletion ordering. Without them, teardown can race and leave deletes stuck or retried in the wrong order.

## Layout

- `argocd/`: root and child Argo CD applications
- `platform/`: Crossplane provider/function/XRD/composition manifests
- `unified-application/`: the Helm chart consumed by Argo CD

## Notes

- The lab assumes a working Crossplane installation.
- The secret import capability assumes External Secrets Operator is installed and a compatible Vault role exists for the configured `SecretStore`.
- The included SQL provider config uses the same local MSSQL example credentials already used elsewhere in this repository.

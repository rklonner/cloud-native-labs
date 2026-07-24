# Crossplane - Abstract an application and infrastructure in a composition

This lab focuses on deploying `RazorApp` projects through Argo CD, surfacing Crossplane-managed resources in the Argo CD UI, and adding custom health checks so Crossplane and External Secrets resources report useful Argo-compatible health.

**Demonstrates**:
* Argo platform installation
* Argo project deployment
* Argo visibility into Crossplane-managed resources
* Argo custom health checks for Crossplane resources

## Quick Start

Prerequisites on your machine:
* `task`
* `docker`
* `kubectl`
* `helm`
* `vcluster`
* `curl`

Bring the full lab up with one command:

```bash
task up
```

## Discover Crossplane resources managed by Argo CD

Log in to Argo CD at `https://localhost:8000` with `admin` / `admin`.

Check `project-aurora` and `project-blade`.
You should see the resources Crossplane created after applying the XRs.
You should also see the correct resource state due to the custom health checks.

Optional:
Log in to Vault at `http://localhost:8200` with token `root` and verify the credentials created for the `aurora` and `blade` projects.

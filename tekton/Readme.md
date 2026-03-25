# Tekton

## Install helm chart in kind cluster
```bash
# Create kind cluster
kind create cluster

# Switch to kind context
kubectl config use-context kind-kind

# Install
kubectl apply --filename \
https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Install dashboard in read/write mode
kubectl apply --filename https://infra.tekton.dev/tekton-releases/dashboard/latest/release-full.yaml

# Install Tekton CLI (optional)
curl -LO https://github.com/tektoncd/cli/releases/download/v0.44.0/tektoncd-cli-0.44.0_Linux-64bit.deb
sudo dpkg -i tektoncd-cli-0.44.0_Linux-64bit.deb

# Verify the installation
kubectl -n tekton-pipelines get pods --watch
```

## Usage
```bash
# Make dashboard available locally
kubectl port-forward -n tekton-pipelines service/tekton-dashboard 9097:9097
```

## Useful commands
````bash
# Watch logs of last pipeline run
tkn pipelinerun logs --last -f 

# Get the Pod name from the TaskRun instance.
kubectl get taskruns -o yaml | grep podName

# Or, get the Pod name from the PipelineRun.
kubectl get pipelineruns -o yaml | grep podName

# Get the logs for all containers in the Pod.
kubectl logs $POD_NAME --all-containers
```
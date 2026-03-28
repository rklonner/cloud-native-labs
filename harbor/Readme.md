# Harbor

# Install

helm repo add harbor https://helm.goharbor.io
helm repo update
helm install harbor harbor/harbor --namespace harbor --create-namespace -f values.yaml

kubectl -n harbor get pods --watch

# Usage
kubectl port-forward svc/harbor -n harbor 8080:443

# Open in browser
http://localhost:8080
Username: admin
Passwort: Harbor12345

# Provide a cluster internal registry

**Demonstrate**:
* How to install Habor with lightweight settings for cluster internal usage (e.g. no metalLB)
* Will be used as registry for /Argo Worflows pipeline

## Prepare environment
```bash
# Install Harbor with custom values provided in this path
helm repo add harbor https://helm.goharbor.io
helm repo update
helm install harbor harbor/harbor --namespace harbor --create-namespace -f values.yaml

# Wait until installation is complete
kubectl -n harbor get pods --watch

# Make kubelet aware of Harbor clusterip service for image fetching
# Get IP of service
SVC_IP=$(kubectl get svc -n harbor harbor -o jsonpath='{.spec.clusterIP}')
# Update /etc/hosts file on kind control plane so that kubelet can resolve to an ip when pulling the image from Harbor
docker exec -it kind-control-plane sh -c "echo '$SVC_IP harbor.harbor.svc.cluster.local' >> /etc/hosts"

# Make kubelet aware of harbor ca for working tls
# Extract ca certificate from nginx pod created during helm installation
kubectl get secret harbor-nginx -n harbor -o jsonpath="{.data['ca\.crt']}" | base64 -d > harbor-ca.crt
# Optional test cacert from a pod when harbor-internal is copied an registered
curl -v --cacert /tmp/harbor-internal.crt https://harbor.harbor.svc.cluster.local
# Copy it into the kind control plane node
docker cp harbor-ca.crt kind-control-plane:/usr/local/share/ca-certificates/harbor-ca.crt
# Update certificates and restart containerd
docker exec kind-control-plane update-ca-certificates
docker exec kind-control-plane systemctl restart containerd

# Test clusterIP registration for hostname and tls settings by doing an https request
docker exec -it kind-control-plane curl -v  https://harbor.harbor.svc.cluster.local
# Test on kind node to pull an Harbor image with crictl
docker exec kind-control-plane crictl pull harbor.harbor.svc.cluster.local/library/my-image:latest

Output:
Image is up to date for sha256:ce8eb5cb9189eb681fae2a67f53c3382e8f6f4775712aec01b346d562f5e7a61

# Forward port for local access
kubectl port-forward svc/harbor -n harbor 8080:443

# Open in browser to test
http://localhost:8080
Username: admin
Passwort: Harbor12345
```

# test harbor-ca file with curl
curl -v --cacert /tmp/harbor-internal.crt https://harbor.harbor.svc.cluster.local

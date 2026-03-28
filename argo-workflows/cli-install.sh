# Detect OS
ARGO_OS="darwin"
if [[ "$(uname -s)" != "Darwin" ]]; then
  ARGO_OS="linux"
fi

# Download the binary
curl -sLO "https://github.com/argoproj/argo-workflows/releases/download/v4.0.3/argo-$ARGO_OS-amd64.gz"

# Unzip
gunzip "argo-$ARGO_OS-amd64.gz"

# Make binary executable
chmod +x "argo-$ARGO_OS-amd64"

# Move binary to path
sudo mv "./argo-$ARGO_OS-amd64" /usr/local/bin/argo

# Test installation
argo version

# Cleanup
rm -f argo-darwin-amd64.gz

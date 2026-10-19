#!/usr/bin/env bash
set -euo pipefail
VERSION="${KAGENT_VERSION:-0.10.3}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
mkdir -p generated
helm template kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --version "$VERSION" --namespace kagent --include-crds > generated/00-crds.yaml
helm template kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --version "$VERSION" --namespace kagent --include-crds \
  -f values-minikube.yaml > generated/10-platform.yaml
python3 local_images.py generated/00-crds.yaml generated/10-platform.yaml > generated/images.txt
echo 'Generated CRD and platform YAML, plus images.txt.'
echo 'Review images.txt, load each listed image into Minikube, then run deploy.sh.'

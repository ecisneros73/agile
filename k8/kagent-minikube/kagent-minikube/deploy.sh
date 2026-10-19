#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[[ -n "${OPENAI_API_KEY:-}" ]] || { echo 'Set OPENAI_API_KEY first' >&2; exit 1; }
kubectl config current-context
kubectl create namespace kagent --dry-run=client -o yaml | kubectl apply -f -
kubectl -n kagent create secret generic kagent-openai \
  --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side -f generated/00-crds.yaml
kubectl wait --for=condition=Established --timeout=180s crd --all || true
kubectl apply -f generated/10-platform.yaml
kubectl get pods -n kagent

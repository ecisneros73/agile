#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[[ -f generated/images.txt ]] || { echo 'Run render.sh first' >&2; exit 1; }
while IFS= read -r image; do
  [[ -z "$image" ]] && continue
  echo "Loading $image"
  docker image inspect "$image" >/dev/null 2>&1 || docker pull "$image"
  minikube image load "$image"
done < generated/images.txt
# Important: if your chart deploys Python/BYO agents, load their runtime images too.
minikube image ls | grep -E 'kagent|kmcp|postgres' || true

#!/usr/bin/env bash
set -euo pipefail
kubectl get deployments,statefulsets,services,serviceaccounts -n kagent
kubectl get pods -n kagent -o wide
kubectl get crds | grep -E 'kagent|kmcp' || true
kubectl get agents -n kagent || true
kubectl get events -n kagent --sort-by=.lastTimestamp | tail -25
kubectl port-forward -n kagent svc/kagent-ui 8080:8080

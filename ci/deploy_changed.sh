#!/usr/bin/env bash
set -e
BED_CTX=$1          # e.g., vcluster context
SERVICES=$2         # "alpha,bravo"
IFS=',' read -ra LIST <<< "$SERVICES"
for svc in "${LIST[@]}"; do
  echo "Applying $svc into $BED_CTX"
  kubectl --context "$BED_CTX" apply -f "ci/k8s/${svc}.yaml"
done

#!/usr/bin/env bash
set -e
SVCS=$1
for svc in ${SVCS//,/ }; do
  echo "--- Testing $svc ---"
  kubectl --context "$KUBECONFIG" port-forward svc/$svc 8080:80 &
  PF=$!; sleep 3
  curl -s http://localhost:8080 | grep -qi $svc
  kill $PF
done

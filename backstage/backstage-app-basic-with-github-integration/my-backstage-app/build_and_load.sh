#!/bin/bash
yarn install --immutable
yarn tsc
yarn build:backend
docker image build . -f packages/backend/Dockerfile --tag backstage

# Load the image into the nodes of the kind cluster
kind load docker-image backstage:latest --name backstage
# Redeploy backstage
kubectl -n backstage rollout restart deployment backstage

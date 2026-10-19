#!/usr/bin/env bash
set -euo pipefail

container_name="mongodb-test"
network_name="kind"

if ! docker inspect "${container_name}" >/dev/null 2>&1; then
  echo "Container ${container_name} not found. Start docker-compose first."
  exit 1
fi

if docker network inspect "${network_name}" >/dev/null 2>&1; then
  if docker network inspect "${network_name}" | grep -q "${container_name}"; then
    echo "${container_name} is already attached to ${network_name}."
    exit 0
  fi
  docker network connect "${network_name}" "${container_name}"
  echo "Connected ${container_name} to ${network_name}."
  exit 0
fi

echo "Docker network ${network_name} not found. If kind uses a different network name on your system, connect the container manually."
exit 1

#!/usr/bin/env bash
# Render prometheus.yml from its template with the targets in .env, then (re)start the stack.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a
envsubst '${NODE_EXPORTER_TARGETS} ${CADVISOR_TARGETS} ${OPNSENSE_EXPORTER_TARGETS}' \
  < prometheus/prometheus.yml.tmpl > prometheus/prometheus.yml
docker compose up -d "$@"

#!/usr/bin/env bash
# apply.sh — envsubst wrapper for kubectl apply
# Usage: ./scripts/apply.sh <template.yaml.tmpl>
#        ./scripts/apply.sh myK8S/authentik/authentik-secrets.yaml.tmpl
#
# Loads .env from myK8S/.env (not committed), substitutes variables, then applies.
# The .env file must be created from .env.example with real values filled in.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <template.yaml.tmpl> [additional kubectl flags]"
  echo "Example: $0 ../clusterIssuer/cf-secret.yaml.tmpl"
  exit 1
fi

TEMPLATE="$1"
shift

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: template file not found: $TEMPLATE"
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found. Copy .env.example to .env and fill in your values."
  exit 1
fi

# Load env file
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

# Substitute and apply
envsubst < "$TEMPLATE" | kubectl apply -f - "$@"

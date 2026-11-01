#!/usr/bin/env bash
# Build the wiki image on this VM from the committed state of the mydocs repo (not the
# working tree, so uncommitted drafts are never published), then restart the container.
# Replaces the Forgejo Actions build + registry (Forgejo is being retired).
#   ./build.sh            # build HEAD of the checked-out branch
#   MYDOCS_REF=main ./build.sh
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck disable=SC1091
set -a; . ./.env; set +a
REF="${MYDOCS_REF:-HEAD}"
REPO="${MYDOCS_REPO_PATH:?set MYDOCS_REPO_PATH in .env}"
echo "building wiki from $REPO @ $(git -c safe.directory="$REPO" -C "$REPO" rev-parse --short "$REF")"
git -c safe.directory="$REPO" -C "$REPO" archive --format=tar "$REF" \
  | docker build -t mydocs-wiki:local -
docker compose up -d --force-recreate wiki
docker image prune -f >/dev/null

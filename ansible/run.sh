#!/usr/bin/env bash
# Run Ansible from Jarvis without installing it: a throwaway container with this folder
# mounted read-only and your SSH key mounted read-only. Pass ansible-playbook arguments.
#
#   ./run.sh baseline.yml --limit utility --check --diff
#   ./run.sh update.yml -e do_reboot=true
#   WAZUH_ENROL_PASS=... ./run.sh install-wazuh-agent.yml -e target=nextcloud
#
# ANSIBLE_CONFIG is set explicitly: this folder is on NFS and world-writable, and Ansible
# ignores an ansible.cfg in a world-writable directory.
set -euo pipefail
cd "$(dirname "$0")"
KEY="${ANSIBLE_SSH_KEY:-$HOME/.ssh/id_ed25519}"
exec docker run --rm -t \
  -v "$PWD:/ansible:ro" \
  -v "$KEY:/root/.ssh/id_ed25519:ro" \
  -v ansible-collections:/root/.ansible/collections \
  -w /ansible \
  -e ANSIBLE_CONFIG=/ansible/ansible.cfg \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  -e WAZUH_ENROL_PASS="${WAZUH_ENROL_PASS:-}" \
  -e DEBIAN_FRONTEND=noninteractive \
  python:3.13-slim sh -c '
    apt-get -qq update >/dev/null 2>&1 && apt-get -qq install -y openssh-client >/dev/null 2>&1
    pip install -q ansible-core >/dev/null 2>&1
    ansible-galaxy collection install community.general ansible.posix >/dev/null 2>&1 || true
    exec ansible-playbook "$@"' sh "$@"

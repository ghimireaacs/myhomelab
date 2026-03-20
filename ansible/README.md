# Ansible

Playbooks for homelab VM management.

## Setup

```bash
pip install ansible
# or
sudo apt install ansible
```

## Inventory

Edit `inventory.ini` to fill in any missing IPs (homeservertoo, k3s master).

## Playbooks

| Playbook | Purpose |
|---|---|
| `update.yml` | apt update + upgrade all VMs, optional reboot |
| `install-docker.yml` | Install Docker on a new VM (official apt repo, adds ghost to docker group) |
| `docker-update.yml` | Pull and recreate changed Docker containers (manual — Watchtower handles this at 3am) |

## Common Commands

```bash
# Test connectivity
ansible all -m ping

# Update all VMs
ansible-playbook update.yml

# Update only Docker VMs
ansible-playbook update.yml -l docker_vms

# Update single host
ansible-playbook update.yml -l ghostmedia

# Update + reboot if needed
ansible-playbook update.yml -e reboot=true

# Dry run (no changes)
ansible-playbook update.yml --check

# Check which hosts need a reboot
ansible linux -m stat -a "path=/var/run/reboot-required"
```

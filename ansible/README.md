# Ansible

Playbooks for homelab VM management.

## Setup

```bash
pip install ansible
# or
sudo apt install ansible
```

Run from a host that holds the SSH private key — the WSL dev box, or Semaphore
(`ansible.example.xyz`), which pulls this repo from GitHub. The VMs themselves
only carry `authorized_keys`, so playbooks cannot be run from `utility`.

## Inventory

| Group | Hosts |
|---|---|
| `docker_vms` | ghostgpu, nextcloud, utility |
| `k3s_workers` | kuberone, kubertwo |
| `k3s_master` | kuber |
| `lxc` | pihole — root login, no Docker |
| `linux` | all of the above |

Home Assistant (116) and Wazuh (118) are not managed here; see the wiki.

## Playbooks

| Playbook | Purpose |
|---|---|
| `backup.yml` | Dump local-disk state to TrueNAS — the only guard against permanent loss |
| `bootstrap.yml` | Blank VM → packages, NFS mount, Docker, agent containers |
| `deploy.yml` | Bring up application stacks from the repo |
| `docker-update.yml` | Pull newer images and restart running stacks |
| `update.yml` | OS patching and Docker pruning |
| `install-docker.yml` | Docker CE from the official repository |

```bash
ansible-playbook backup.yml
ansible-playbook update.yml -e do_reboot=true
ansible-playbook deploy.yml --limit utility -e stack=mattermost
```

## Backups

`backup.yml` writes to `90_Backups/ansible/<host>/` on TrueNAS with 14 days of
retention. Databases are discovered by container image rather than listed, so a
new Postgres is backed up as soon as it exists. Non-database state — named
volumes and local directories — is declared per host in `host_vars/`.

**Adding a service that stores anything on a VM's local disk means adding it to
that host's `host_vars` file.** Nothing else backs it up. Prefer putting state
on NFS in the first place, in which case no entry is needed.

Full restore procedures: wiki → guides → Disaster Recovery.

## Conventions

- Playbooks are idempotent; re-running is always safe.
- Per-host failures never abort the run — a stack belonging to another host, or
  one missing its `.env`, is reported and skipped.
- `backup.yml` refuses to write if the NFS mount is absent, rather than filling
  a local disk with backups that would die with the host.

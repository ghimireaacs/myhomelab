# Ansible

Playbooks for homelab host management.

## Running

Jarvis is the control node (it holds the SSH key every host trusts). Ansible is not
installed on it; `run.sh` runs it in a throwaway container:

```bash
cd myhomelab/ansible
./run.sh baseline.yml --limit utility --check --diff   # always dry-run first
./run.sh baseline.yml --limit utility
./run.sh backup.yml
./run.sh update.yml -e do_reboot=true
WAZUH_ENROL_PASS='...' ./run.sh install-wazuh-agent.yml -e target=nextcloud
```

`ANSIBLE_CONFIG` must be set when running Ansible any other way: this folder is on NFS
and world-writable, and Ansible ignores `ansible.cfg` in a world-writable directory.
Semaphore (`ansible.example.xyz`) can also run these from the GitHub copy of the repo.

## Inventory

| Group | Hosts |
|---|---|
| `docker_vms` | ghostgpu, nextcloud, utility |
| `proxmox` | homeserver, homeservertoo |
| `lxc` | pihole (root login, no Docker) |
| `workstation` | jarvis (local connection) |
| `linux` | all of the above |

Not managed: Home Assistant OS (116), Wazuh (VLAN 60), wallstreet (103, address not yet
recorded). Retired 2026-11-02: kuberone, kubertwo, kuber.

Jarvis's key is not yet on **nextcloud**: install it with `jarvis-key/` before running
anything against that host.

## Playbooks

| Playbook | Purpose |
|---|---|
| `baseline.yml` | What every host should have (below). Safe to re-run; dry-run with `--check --diff` |
| `bootstrap.yml` | Blank VM → packages, NFS mount, Docker, agent containers; then run `baseline.yml` |
| `install-wazuh-agent.yml` | Wazuh agent pinned to the manager's version; needs `WAZUH_ENROL_PASS` |
| `backup.yml` | Dump local-disk state to TrueNAS — the only guard against permanent loss |
| `deploy.yml` | Bring up application stacks from the repo |
| `docker-update.yml` | Pull newer images and restart running stacks |
| `update.yml` | OS patching and Docker pruning |
| `install-docker.yml` | Docker CE from the official repository |

### What `baseline.yml` enforces

Built from a survey of every reachable host on 2026-11-02, which found password SSH
still enabled on utility, both Proxmox hosts and Pi-hole, no journal or Docker log
limits anywhere, and Docker's default network pools exhausted on utility.

- SSH: keys only (`PasswordAuthentication no`), no X11, `MaxAuthTries 3`; root login
  `no` on VMs, `prohibit-password` where root is the login user (Proxmox, Pi-hole).
  The managed public keys are in `files/authorized_keys.ghost`; additive until
  `baseline_keys_exclusive=true`.
- Logs: journald capped at 500M / 1 month; Docker `json-file` logs rotated at 3×10 MB.
- Updates: unattended **security** updates only, never an automatic reboot (not on Proxmox).
- Docker: `daemon.json` = rotation + /24 address pools + `live-restore`, merged with
  `docker_daemon_extra` from host_vars; an exposed `tcp://` socket is refused.
  Docker is only restarted with `-e baseline_restart_docker=true`.
- Housekeeping: timezone Australia/Sydney, `fstrim.timer`, guest agent on VMs.
- Report only (never changed): unexpected login users, ports open on all interfaces,
  pending reboot.

## Backups

`backup.yml` writes to `90_Backups/ansible/<host>/` on TrueNAS with 14 days of
retention. Databases are discovered by container image rather than listed, so a
new Postgres is backed up as soon as it exists. Non-database state — named
volumes and local directories — is declared per host in `host_vars/`.

**Adding a service that stores anything on a VM's local disk means adding it to
that host's `host_vars` file.** Nothing else backs it up. As of 2026-11-02 the run is
**not scheduled** anywhere; see the hardening plan in the wiki.

## Conventions

- Playbooks are idempotent; re-running is always safe.
- Per-host failures never abort the run — a stack belonging to another host, or
  one missing its `.env`, is reported and skipped.
- `backup.yml` refuses to write if the NFS mount is absent, rather than filling
  a local disk with backups that would die with the host.

# Jarvis SSH key

One playbook that adds Jarvis's public key to every box, or removes it.

## Run

From a host whose key is already on every box: the workstation or Semaphore.
Jarvis can't run it, because Jarvis is the box being given access.

```bash
cd myhomelab/ansible/jarvis-key
export ANSIBLE_CONFIG=../ansible.cfg   # required, see below

# Add
ansible-playbook -i ../inventory.ini -i hosts.ini jarvis-key.yml

# Remove
ansible-playbook -i ../inventory.ini -i hosts.ini jarvis-key.yml -e key_state=absent

# One group or host
ansible-playbook -i ../inventory.ini -i hosts.ini jarvis-key.yml -e target=proxmox
```

Pass both `-i` files: `../inventory.ini` holds the VMs, k3s nodes and pihole,
and `hosts.ini` adds the boxes it leaves out (both Proxmox hosts, `proxmox3` and
`wazuh` on the defence box).

`ANSIBLE_CONFIG` is not optional. This folder is world-writable on the NFS
share (`mapall`), so Ansible ignores any `ansible.cfg` here unless the path is
given explicitly. Without it, host key checking turns back on and the run stops
at a yes/no prompt for any host not yet in `known_hosts`.

Needs the `ansible.posix` collection, which the full `ansible` package
includes. With bare `ansible-core`, run `ansible-galaxy collection install ansible.posix`.

## What it touches

| Box | Account |
|---|---|
| Docker VMs, k3s nodes, wazuh, Proxmox hosts | `ghost` |
| pihole LXC | `root` |

The key is added to whichever account Ansible logs in as on that host. Only
the one key line changes, and no other keys are touched. Re-running is safe.

Not covered: TrueNAS and OPNsense keep their keys in their own config
databases (add through the web UI), and Home Assistant OS has no shell.

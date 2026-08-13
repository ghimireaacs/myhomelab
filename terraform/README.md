# Terraform — Proxmox VMs

Declares the Proxmox VMs. Each VM carries its own hardware spec, because the
fleet is not uniform.

## Status

The VMs listed in `homelab.tfvars.example` were all created by hand before this
config existed. **Terraform does not own them until they are imported.** Running
`apply` first would try to build a second copy of every machine.

## Setup

```bash
cp homelab.tfvars.example homelab.tfvars   # fill in real IPs
cp secrets.tfvars.example secrets.tfvars   # Proxmox API token
terraform init
```

State is local and gitignored. Since it can be rebuilt by re-importing, it is
not something to back up — but a lost state file does mean redoing the imports
below.

## Adopting the existing VMs

Import one at a time, and confirm each is clean before moving on:

```bash
# terraform import 'module.vm["<name>"].proxmox_vm_qemu.vm' <node>/<vmid>
terraform import -var-file=homelab.tfvars -var-file=secrets.tfvars \
  'module.vm["utility"].proxmox_vm_qemu.vm' homeserver/114

terraform plan -var-file=homelab.tfvars -var-file=secrets.tfvars
```

The goal is a plan showing **no changes**. If it wants to modify a VM, the
tfvars do not match reality — correct the tfvars, never "fix" it by applying.
Disk and network drift is already suppressed via `ignore_changes` in the
module, because Proxmox reports those fields differently than they are declared.

## Adding a new VM

Add an entry to `vms` with a free VMID, then:

```bash
terraform apply -var-file=homelab.tfvars -var-file=secrets.tfvars
ansible-playbook ../ansible/bootstrap.yml --limit <name>
ansible-playbook ../ansible/deploy.yml --limit <name>
```

## Scope

This module creates `proxmox_vm_qemu` resources only. The Pi-hole LXC, the Home
Assistant OS appliance and the script-built Wazuh VM are outside it and are
rebuilt by hand — see the disaster recovery runbook in the wiki.

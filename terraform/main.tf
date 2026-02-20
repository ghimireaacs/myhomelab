locals {
  # Stable ordering ensures consistent VMID assignment across runs
  vm_names = sort(keys(var.vms))

  bootstrap_ssh_key = trimspace(file(var.ssh_pubkey_path))
}

module "vm" {
  source = "./modules/vm"

  for_each = var.vms

  name        = each.key
  target_node = var.target_node
  vmid        = var.vmid_start + index(local.vm_names, each.key)

  clone_template = var.clone_template
  storage        = var.storage
  bridge         = var.bridge

  memory    = var.memory
  cores     = var.cores
  disk_size = var.disk_size

  ip      = each.value
  cidr    = var.cidr
  gateway = var.gateway

  ciuser  = var.ciuser
  sshkeys = local.bootstrap_ssh_key
}

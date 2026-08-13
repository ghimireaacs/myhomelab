locals {
  bootstrap_ssh_key = trimspace(file(var.ssh_pubkey_path))
}

# VMIDs are declared per VM rather than derived from an index, so that state
# matches the machines that already exist and `terraform import` lines up.
module "vm" {
  source = "./modules/vm"

  for_each = var.vms

  name        = each.key
  vmid        = each.value.vmid
  target_node = coalesce(each.value.target_node, var.target_node)

  clone_template = coalesce(each.value.template, var.clone_template)
  storage        = var.storage
  bridge         = var.bridge

  memory    = each.value.memory
  cores     = each.value.cores
  disk_size = each.value.disk_size
  onboot    = each.value.onboot

  ip      = each.value.ip
  cidr    = var.cidr
  gateway = var.gateway

  ciuser  = var.ciuser
  sshkeys = local.bootstrap_ssh_key
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.name
  target_node = var.target_node
  vmid        = var.vmid

  # Clone from template
  clone      = var.clone_template
  full_clone = true

  # Hardware
  memory  = var.memory
  cores   = var.cores
  sockets = 1
  cpu     = "host"
  agent   = 1 # QEMU guest agent (must be installed in template)

  # Boot disk
  disk {
    slot    = 0
    type    = "scsi"
    storage = var.storage
    size    = var.disk_size
  }

  # Network
  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Cloud-init
  os_type   = "cloud-init"
  ipconfig0 = "ip=${var.ip}/${var.cidr},gw=${var.gateway}"
  ciuser    = var.ciuser
  sshkeys   = var.sshkeys

  # Prevent Terraform from detecting drift on fields managed outside TF
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

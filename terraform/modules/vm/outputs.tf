output "vm_name" {
  description = "VM hostname"
  value       = proxmox_vm_qemu.vm.name
}

output "vm_ip" {
  description = "VM static IP address"
  value       = var.ip
}

output "vmid" {
  description = "Proxmox VMID"
  value       = proxmox_vm_qemu.vm.vmid
}

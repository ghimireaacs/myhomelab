variable "name" {
  description = "VM name in Proxmox"
  type        = string
}

variable "vmid" {
  description = "Explicit VMID — must match the existing VM when importing"
  type        = number
}

variable "target_node" {
  description = "Proxmox node to create the VM on"
  type        = string
}

variable "clone_template" {
  description = "Template to full-clone"
  type        = string
}

variable "storage" {
  description = "Storage pool for the disk"
  type        = string
}

variable "bridge" {
  description = "Network bridge"
  type        = string
}

variable "memory" {
  description = "RAM in MB"
  type        = number
}

variable "cores" {
  description = "vCPU cores"
  type        = number
}

variable "disk_size" {
  description = "Disk size, e.g. 32G"
  type        = string
}

variable "onboot" {
  description = "Start the VM when the host boots"
  type        = bool
  default     = true
}

variable "ip" {
  description = "Static IPv4 address"
  type        = string
}

variable "cidr" {
  description = "Network prefix length"
  type        = number
}

variable "gateway" {
  description = "Default gateway"
  type        = string
}

variable "ciuser" {
  description = "Cloud-init user"
  type        = string
}

variable "sshkeys" {
  description = "Public keys for the cloud-init user"
  type        = string
}

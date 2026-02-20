variable "name" {
  description = "VM hostname"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to place this VM on"
  type        = string
}

variable "vmid" {
  description = "Proxmox VMID"
  type        = number
}

variable "clone_template" {
  description = "Template VM name to clone from"
  type        = string
}

variable "storage" {
  description = "Proxmox storage pool for disk"
  type        = string
}

variable "bridge" {
  description = "Network bridge"
  type        = string
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 4096
}

variable "cores" {
  description = "vCPU cores"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Root disk size (e.g. '32G')"
  type        = string
  default     = "32G"
}

variable "ip" {
  description = "Static IP address for this VM"
  type        = string
}

variable "cidr" {
  description = "Subnet prefix length"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Default gateway"
  type        = string
}

variable "ciuser" {
  description = "Cloud-init username"
  type        = string
  default     = "ghost"
}

variable "sshkeys" {
  description = "SSH public key(s) to inject via cloud-init"
  type        = string
}

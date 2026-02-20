# ---------------------------------------------------------------------------
# Provider credentials — set via secrets.tfvars (gitignored)
# ---------------------------------------------------------------------------

variable "pm_api_url" {
  description = "Proxmox API URL (e.g. https://homeserver:8006/api2/json)"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID (e.g. terraform@pam!mytoken)"
  type        = string
  sensitive   = true
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret (UUID)"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Skip TLS verification for Proxmox API (set true for self-signed certs)"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# VM definitions — set via homelab.tfvars (gitignored)
# ---------------------------------------------------------------------------

variable "vms" {
  description = "Map of VM name → static IP address"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Cluster defaults — override per environment in tfvars if needed
# ---------------------------------------------------------------------------

variable "target_node" {
  description = "Proxmox node name to deploy VMs on"
  type        = string
  default     = "homeserver"
}

variable "vmid_start" {
  description = "Base VMID — VMs are assigned vmid_start + sorted index"
  type        = number
  default     = 300
}

variable "clone_template" {
  description = "Name of the Proxmox template VM to clone"
  type        = string
  default     = "tf-debian-template"
}

variable "storage" {
  description = "Proxmox storage pool for VM disk and cloud-init drive"
  type        = string
  default     = "wdstorageHDD"
}

variable "bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Default gateway for VM network config (e.g. 192.168.1.1)"
  type        = string
}

variable "cidr" {
  description = "Subnet prefix length (e.g. 24 for /24)"
  type        = number
  default     = 24
}

variable "memory" {
  description = "RAM in MB for each VM"
  type        = number
  default     = 4096
}

variable "cores" {
  description = "vCPU cores per VM"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Root disk size (e.g. '32G')"
  type        = string
  default     = "32G"
}

variable "ciuser" {
  description = "Cloud-init username"
  type        = string
  default     = "ghost"
}

variable "ssh_pubkey_path" {
  description = "Path to SSH public key injected via cloud-init"
  type        = string
  default     = "./ssh/bootstrap.pub"
}

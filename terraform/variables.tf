variable "pm_api_url" {
  description = "Proxmox API endpoint, e.g. https://10.0.0.1:8006/api2/json"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID (user@realm!tokenname)"
  type        = string
  sensitive   = true
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Skip TLS verification — true for a self-signed Proxmox certificate"
  type        = bool
  default     = true
}

variable "vms" {
  description = <<-EOT
    VMs to manage, keyed by name. Each VM declares its own hardware, because
    the fleet is not uniform — sizes range from a 512 MB LXC-scale guest to an
    8 GB GPU host. Every field except `ip` and `vmid` has a default.
  EOT
  type = map(object({
    vmid        = number
    ip          = string
    memory      = optional(number, 4096)
    cores       = optional(number, 2)
    disk_size   = optional(string, "32G")
    target_node = optional(string)
    template    = optional(string)
    onboot      = optional(bool, true)
  }))
}

variable "target_node" {
  description = "Default Proxmox node for VMs that do not name one"
  type        = string
  default     = "homeserver"
}

variable "clone_template" {
  description = <<-EOT
    Default template to clone. Use the Ubuntu Docker template — its cloud-init
    provides the ghost user, the NFS mount and the always-on agent containers
    that the Ansible playbooks and the rest of the homelab assume.
  EOT
  type        = string
  default     = "docker-template"
}

variable "storage" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Default gateway"
  type        = string
}

variable "cidr" {
  description = "Network prefix length"
  type        = number
  default     = 24
}

variable "ciuser" {
  description = "Cloud-init user"
  type        = string
  default     = "ghost"
}

variable "ssh_pubkey_path" {
  description = "Public key injected via cloud-init"
  type        = string
  default     = "./ssh/bootstrap.pub"
}

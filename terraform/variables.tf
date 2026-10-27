variable "subscription_id" {
  description = "Your Azure subscription ID (run: az account show --query id -o tsv)"
  type        = string
}

variable "prefix" {
  description = "Prefix used for naming all resources"
  type        = string
  default     = "devopsia3"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}

variable "vm_size" {
  description = "VM size (B1s is the cheapest general-purpose size)"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin user on the VM (Jenkins deploys as this user)"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used to log in to the VM"
  type        = string
  default     = "~/.ssh/devops_ia3.pub"
}

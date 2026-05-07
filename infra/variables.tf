variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "prj" {
  description = "Project name"
  type        = string
  default     = "at-avd"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "adds_vm_size" {
  description = "VM size for ADDS server"
  type        = string
  default     = "Standard_D2as_v7"
}

variable "adds_admin_username" {
  description = "Admin username for ADDS VM"
  type        = string
  default     = "azureuser"
}

variable "adds_admin_password" {
  description = "Admin password for ADDS VM"
  type        = string
  sensitive   = true
}

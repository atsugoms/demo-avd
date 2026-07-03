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

variable "session_host_vm_size" {
  description = "VM size for AVD session hosts"
  type        = string
  default     = "Standard_B2as_v2"
}

variable "session_host_admin_username" {
  description = "Admin username for AVD session hosts"
  type        = string
  default     = "azureuser"
}

variable "session_host_admin_password" {
  description = "Admin password for AVD session hosts"
  type        = string
  sensitive   = true
}

variable "session_host_count" {
  description = "Number of AVD session hosts to create"
  type        = number
  default     = 1

  validation {
    condition     = var.session_host_count >= 1
    error_message = "session_host_count must be greater than or equal to 1."
  }
}

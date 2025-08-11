#===============================================================================
# Enhanced Variables for High Availability Configuration
#
# Additional variables required for the HA-enhanced FortiWeb deployment
#===============================================================================

# High Availability Configuration
variable "hub_nva_high_availability" {
  type        = bool
  description = "Enable high availability deployment with multiple FortiWeb instances across availability zones"
  # Temporarily disabled to clear conflicting HA resources from state
  default = false
}

variable "hub_nva_admin_username" {
  type        = string
  description = "Admin username for FortiWeb NVA instances"
  default     = "azureadmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{2,63}$", var.hub_nva_admin_username))
    error_message = "Admin username must start with a letter and be 3-64 characters long, containing only alphanumeric characters, underscores, and hyphens."
  }
}

# Monitoring Configuration
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for diagnostic settings and monitoring"
  default     = ""
  sensitive   = true
}


# Enhanced Network Configuration
variable "hub_internal_subnet_address_prefix" {
  type        = string
  description = "Hub Internal Subnet Address prefix for NVA backend connectivity"
  default     = "10.0.1.0/26"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$", var.hub_internal_subnet_address_prefix))
    error_message = "The subnet must be in valid CIDR format 'xxx.xxx.xxx.xxx/xx'."
  }
}

# Load Balancer Configuration
variable "hub_nva_lb_sku_tier" {
  type        = string
  description = "Load Balancer SKU tier (Regional or Global)"
  default     = "Regional"

  validation {
    condition     = contains(["Regional", "Global"], var.hub_nva_lb_sku_tier)
    error_message = "Load Balancer SKU tier must be either 'Regional' or 'Global'."
  }
}

variable "hub_nva_health_check_interval" {
  type        = number
  description = "Health check interval in seconds for load balancer probes"
  default     = 30

  validation {
    condition     = var.hub_nva_health_check_interval >= 15 && var.hub_nva_health_check_interval <= 300
    error_message = "Health check interval must be between 15 and 300 seconds."
  }
}

# Instance Configuration
variable "hub_nva_instance_size_production" {
  type        = string
  description = "VM size for FortiWeb instances in production environment"
  default     = "Standard_F4s_v2"

  validation {
    condition = contains([
      "Standard_F2s_v2", "Standard_F4s_v2", "Standard_F8s_v2", "Standard_F16s_v2",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3", "Standard_D16s_v3"
    ], var.hub_nva_instance_size_production)
    error_message = "Instance size must be a valid Azure VM size for network appliances."
  }
}

variable "hub_nva_instance_size_development" {
  type        = string
  description = "VM size for FortiWeb instances in development environment"
  default     = "Standard_F2s_v2"

  validation {
    condition = contains([
      "Standard_F2s_v2", "Standard_F4s_v2", "Standard_D2s_v3", "Standard_D4s_v3"
    ], var.hub_nva_instance_size_development)
    error_message = "Instance size must be a valid Azure VM size for development."
  }
}

# Disk Configuration
variable "hub_nva_os_disk_type" {
  type        = string
  description = "OS disk storage type for FortiWeb instances"
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.hub_nva_os_disk_type)
    error_message = "OS disk type must be Standard_LRS, StandardSSD_LRS, or Premium_LRS."
  }
}

variable "hub_nva_os_disk_size" {
  type        = number
  description = "OS disk size in GB for FortiWeb instances"
  default     = 64

  validation {
    condition     = var.hub_nva_os_disk_size >= 64 && var.hub_nva_os_disk_size <= 1024
    error_message = "OS disk size must be between 64 GB and 1024 GB."
  }
}

# Cluster Configuration
variable "hub_nva_cluster_sync_timeout" {
  type        = number
  description = "Timeout in seconds for HA cluster synchronization"
  default     = 300

  validation {
    condition     = var.hub_nva_cluster_sync_timeout >= 60 && var.hub_nva_cluster_sync_timeout <= 1800
    error_message = "Cluster sync timeout must be between 60 and 1800 seconds."
  }
}

# Availability Zones
variable "hub_nva_availability_zones" {
  type        = list(string)
  description = "Availability zones for FortiWeb instance deployment"
  default     = ["1", "2"]

  validation {
    condition     = length(var.hub_nva_availability_zones) >= 1 && length(var.hub_nva_availability_zones) <= 3
    error_message = "Must specify between 1 and 3 availability zones."
  }

  validation {
    condition = alltrue([
      for zone in var.hub_nva_availability_zones : contains(["1", "2", "3"], zone)
    ])
    error_message = "Availability zones must be '1', '2', or '3'."
  }
}
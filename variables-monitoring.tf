#===============================================================================
# Enhanced Monitoring Variables
#
# Additional variables for comprehensive monitoring and observability
#===============================================================================

# Alerting Configuration
variable "teams_webhook_url" {
  type        = string
  description = "Microsoft Teams webhook URL for critical alerts"
  default     = ""
  sensitive   = true
  
  validation {
    condition     = var.teams_webhook_url == "" || can(regex("^https://[a-zA-Z0-9.-]+\\.webhook\\.office\\.com/", var.teams_webhook_url))
    error_message = "Teams webhook URL must be a valid Microsoft Teams webhook URL or empty string."
  }
}

variable "enable_network_flow_logs" {
  type        = bool
  description = "Enable Network Security Group flow logs and traffic analytics"
  default     = true
}

variable "monitoring_retention_days" {
  type        = number
  description = "Retention period in days for monitoring data"
  default     = 30
  
  validation {
    condition     = var.monitoring_retention_days >= 7 && var.monitoring_retention_days <= 730
    error_message = "Monitoring retention days must be between 7 and 730."
  }
}

variable "log_analytics_daily_quota_gb" {
  type        = number
  description = "Daily ingestion quota in GB for Log Analytics workspace"
  default     = 5
  
  validation {
    condition     = var.log_analytics_daily_quota_gb >= 0.1 && var.log_analytics_daily_quota_gb <= 1000
    error_message = "Log Analytics daily quota must be between 0.1 GB and 1000 GB."
  }
}

# Alert Thresholds
variable "cpu_alert_threshold" {
  type        = number
  description = "CPU utilization percentage threshold for alerts"
  default     = 85
  
  validation {
    condition     = var.cpu_alert_threshold >= 50 && var.cpu_alert_threshold <= 95
    error_message = "CPU alert threshold must be between 50% and 95%."
  }
}

variable "memory_alert_threshold_mb" {
  type        = number
  description = "Available memory threshold in MB for alerts"
  default     = 512
  
  validation {
    condition     = var.memory_alert_threshold_mb >= 256 && var.memory_alert_threshold_mb <= 2048
    error_message = "Memory alert threshold must be between 256 MB and 2048 MB."
  }
}

variable "response_time_alert_threshold_ms" {
  type        = number
  description = "Application response time threshold in milliseconds for alerts"
  default     = 5000
  
  validation {
    condition     = var.response_time_alert_threshold_ms >= 1000 && var.response_time_alert_threshold_ms <= 30000
    error_message = "Response time alert threshold must be between 1000 ms and 30000 ms."
  }
}

# Dashboard Configuration
variable "enable_custom_dashboard" {
  type        = bool
  description = "Enable creation of custom monitoring dashboard"
  default     = true
}

variable "dashboard_time_range" {
  type        = string
  description = "Default time range for dashboard widgets"
  default     = "PT1H"
  
  validation {
    condition     = contains(["PT1H", "PT6H", "PT12H", "P1D", "P3D", "P7D"], var.dashboard_time_range)
    error_message = "Dashboard time range must be one of: PT1H, PT6H, PT12H, P1D, P3D, P7D."
  }
}

# Monitoring Features
variable "enable_application_insights" {
  type        = bool
  description = "Enable Application Insights for application monitoring"
  default     = true
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable Container Insights for AKS monitoring"
  default     = true
}

variable "enable_vm_insights" {
  type        = bool
  description = "Enable VM Insights for virtual machine monitoring"
  default     = true
}

# Cost Management
variable "monitoring_budget_amount" {
  type        = number
  description = "Monthly budget amount in USD for monitoring costs"
  default     = 100
  
  validation {
    condition     = var.monitoring_budget_amount >= 10 && var.monitoring_budget_amount <= 10000
    error_message = "Monitoring budget amount must be between $10 and $10,000."
  }
}

variable "enable_cost_alerts" {
  type        = bool
  description = "Enable cost-based alerts for monitoring services"
  default     = true
}
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location for resources"
  type        = string
  default     = "eastus"
}

variable "owner_email" {
  description = "Email of the resource owner"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Address space for hub VNet"
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "spoke_vnet_address_space" {
  description = "Address space for spoke VNet"
  type        = list(string)
  default     = ["10.200.0.0/16"]
}

variable "hub_external_subnet" {
  description = "Hub external subnet CIDR"
  type        = string
  default     = "10.100.1.0/24"
}

variable "spoke_aks_subnet" {
  description = "Spoke AKS subnet CIDR"
  type        = string
  default     = "10.200.1.0/24"
}
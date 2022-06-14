variable "aws_vpc_id" {
  type        = string
  description = "the id of the aws vpc"
}

variable "aws_route_table_ids" {
  type        = list(string)
  description = "aws route tables to add vpn routes to"
}

variable "azure_resource_group_name" {
  type        = string
  description = "name of the azure resource group to use"
}

variable "azure_location" {
  type        = string
  description = "name of the azure location to use"
}

variable "azure_network_name" {
  type        = string
  description = "name of the azure virtual network to use"
}

variable "azure_network_address_space" {
  type        = list(string)
  description = "azure cidr blocks to give access to the VPN"
}

variable "azure_gateway_cidr" {
  type        = string
  description = "cidr block of azure gateway subnet (recommended /27 or larger)"
}

variable "azure_gateway_sku" {
  type        = string
  description = "product sku of azure vpn gateway"
  default     = "VpnGw1"
}

variable "dns_network_acl_id" {
  type        = string
  description = "network acl id of the dns subnet"
}

locals {
  dns_port = 53
}

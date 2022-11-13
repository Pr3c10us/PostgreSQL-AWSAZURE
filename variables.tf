variable "aws_region" {
  type        = string
  description = "aws region to use"
}

variable "aws_access_key" {
  type        = string
  description = "AWS access key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key"
}

variable "aws_dns_suffix" {
  type        = string
  description = "DNS suffix that AWS uses for internal host names (e.g., ec2.internal, compute.internal)"
}

variable "aws_directory_service_password" {
  type        = string
  description = "password to use for the aws directory service (enabling DNS)"
}

variable "azure_resource_group_name" {
  type        = string
  description = "azure resource group to use"
}

variable "azure_location" {
  type        = string
  description = "azure location to use"
}

variable "az_subscription_id" {
  type = string
}

variable "az_client_id" {
  type = string
}

variable "az_client_secret" {
  type = string
}
variable "az_tenant_id" {
  type = string
}
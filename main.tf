# Create azure resource group

# resource "random_pet" "rg-name" {
#   prefix    = "pg"
# }

# resource "azurerm_resource_group" "rg" {
#   name      = random_pet.rg-name.id
#   location  = var.azure_location
# }

resource "azurerm_resource_group" "rg" {
  name      = var.azure_resource_group_name
  location  = var.azure_location
}


module "aws_vpc" {
  source = "./aws/vpc"

  vpc_name     = "aws-test"
  cidr_block   = "10.0.0.0/16"
  subnet_count = 1
}

module "dns" {
  source = "./aws/dns"

  vpc_id                 = module.aws_vpc.vpc_id
  directory_name         = "test.internal"
  directory_password     = var.aws_directory_service_password
  dns_subnet_cidr_prefix = "10.0.0.0/20"
  private_route_table_id = module.aws_vpc.private_route_table_id
}

module "aws_instance" {
  source = "./aws/ubuntu_instance"

  public_subnet_id = module.aws_vpc.public_subnet_id
  aws_vpc_id        = module.aws_vpc.vpc_id

  # Application Definition 
  app_name        = "aws-db" # Do NOT enter any spaces
  app_environment = "dev"       # Dev, Test, Staging, Prod, etc

  # Linux Virtual Machine
  linux_instance_type               = "t3.large"
  linux_associate_public_ip_address = true
  linux_root_volume_size            = 20
  linux_root_volume_type            = "gp2"
  linux_data_volume_size            = 10
  linux_data_volume_type            = "gp2"
}


module "aws_awx_instance" {
  source = "./aws/ansible"

  public_subnet_id = module.aws_vpc.public_subnet_id
  aws_vpc_id       = module.aws_vpc.vpc_id

  # Application Definition 
  app_name        = "awx-server" # Do NOT enter any spaces
  app_environment = "dev"        # Dev, Test, Staging, Prod, etc

  # Linux Virtual Machine
  linux_instance_type               = "t2.micro"
  linux_associate_public_ip_address = true
  linux_root_volume_size            = 20
  linux_root_volume_type            = "gp2"
  linux_data_volume_size            = 10
  linux_data_volume_type            = "gp2"
}



module "azure_instance" {
  source = "./azure/ubuntu_instance"

  resource_group_name                = azurerm_resource_group.rg.name
  resource_group_location            = var.azure_location
}

# module "azure_vnet" {
#   source = "./azure/vnet"

#   resource_group_name = azurerm_resource_group.rg.name
#   location            = var.azure_location
#   network_name        = "azure-test"
#   cidr_block          = "10.2.0.0/16"
#   subnet_count        = 1
#   dns_servers         = module.dns.dns_ip_addresses
# }

# module "vpn" {
#   source = "./vpn"

#   aws_vpc_id          = module.aws_vpc.vpc_id
#   aws_route_table_ids = [module.aws_vpc.private_route_table_id, module.aws_vpc.public_route_table_id]

#   azure_resource_group_name   = azurerm_resource_group.rg.name
#   azure_location              = var.azure_location
#   azure_network_name          = module.azure_vnet.network_name
#   azure_network_address_space = module.azure_vnet.address_space
#   azure_gateway_cidr          = "10.2.0.0/27"

#   dns_network_acl_id = module.dns.dns_network_acl_id
# }

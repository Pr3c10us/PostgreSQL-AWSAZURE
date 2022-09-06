
# this vpc should set both EnableDnsSupport,EnableDnsHostnames to true
variable "aws_vpc_id" {
  type = string
}

# variable "blue_database_host" {
#   type = string
# }

variable "lambda_function_name" {
  default = "replicate_function"
}

variable "create_database_function" {
  default = "create_database_instance_function"
}

variable "switch_blue_to_green_function" {
  default = "switch_blue_to_green_function"
}

variable "create_database_function" {
  default = "create_database_function"
}
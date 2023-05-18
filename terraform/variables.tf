variable "instance_name" {
  description = "test vicuna"
  type        = string
  default     = "test-vicuna-g5"
}

variable "instance_type" {
  type    = string
  default = "t3g.xlarge"
}

variable "ami" {
  type = string
}

variable "project_tag" {
  type    = string
  default = "llm-handson"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# variable "public_subnet" {
#   default = {
#     "public_subnet_1" = 1
#   }
# }

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

# variable "private_subnet" {
#   default = {
#     "private_subnet_1" = 1
#   }
# }

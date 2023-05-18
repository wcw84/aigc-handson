project_tag   = "llm-handson"
## VPC & EC2
aws_region          = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.0.0/24"
private_subnet_cidr = "10.0.1.0/24"
## ami list:
# amazon linux ami-0889a44b331db0194 (64-bit (x86)) / ami-08fc6fb8ad2e794bb (64-bit (Arm))
# amazon linux 2 ami-06a0cd9728546d178 (64-bit (x86)) / ami-09e51988f56677f44 (64-bit (Arm))
# ubuntu 22 ami-007855ac798b5175e (64-bit (x86)) / ami-0c6c29c5125214c77 (64-bit (Arm))
ami           = "ami-007855ac798b5175e" #ubuntu 22 x86
instance_type = "g5.12xlarge"

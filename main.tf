
# terraform.tf file content ----------------------------------------
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "6.2.0"
        }
        random = {
            source = "hashicorp/random"
            version = "3.7.2"
        }
    }
}

# providrs.tf file  content -----------------------------
provider "aws" {
    region = var.aws_region
}

# variables.tf file content ------------------------------
variable "environment" {
    type = string
    default = "testing"
}

variable "created_by_user" {
    type = string
    default = "Aditya Bahuguna"
}

variable "aws_region" {
    type = string
    default = "ap-south-1"
}

variable "ami_id" {
    type = string
    default = "ami-0d03cb826412c6b0f" # amazon linux 2
}

variable "instance_type" {
    type = string
    default = "t2.micro"
}


# vpc.tf file content -----------------------------------------
module "my_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment}-my-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["ap-south-1a"]
  private_subnets = ["10.10.1.0/24"]
  public_subnets  = ["10.10.2.0/24"]

  enable_nat_gateway      = true  # creates NAT GW in all AZS 
  single_nat_gateway      = true  # default 1 NAT GW | if use multi AZS then does - false for per AZs | if want in all azs then does - true
  map_public_ip_on_launch = true
  enable_dns_support      = true
  enable_dns_hostnames    = true

  tags = {
        Name        = "${var.environment}-my-vpc"
        Terraform   = "true"
        Environment = var.environment
        created_by  = var.created_by_user
    }
}

# security_group.tf file content -------------------------------------
# by the resource

# resource "aws_security_group" "my-sg" {

#     name = "${var.environment}-my-sg"
#     description = "this security group in for http, ssh"
#     vpc_id = module.my_vpc.vpc_id

#     ingress = [{
#       from_port   = 80
#       to_port     = 80
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]  
#     },
#     {
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]  
#     }]

#     egress {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]  
#     }

#      tags = {
#         Name        = "${var.environment}-my-sg"
#         Terraform   = "true"
#         Environment = var.environment
#         created_by  = var.created_by_user
#     }
# }

# by the module security_group.tf ------------------------------

module "my-sg" {
    source  = "terraform-aws-modules/security-group/aws"

    name = "${var.environment}-my-sg"
    description = "this sg is to allow http, ssh, https"
    vpc_id = module.my_vpc.vpc_id


    # ingress_rules = ["ssh","http","https"]  # use this for specific ports known, not for custom ports like - 3000, 8080, 9000 , use- "mysql 3306", "postgresql 5432" "RDP 3389" , ports 

    # for custom ports use ingress_with_cidr_blocks.

    # prority high to run | we have not use both ingress_rules and ingress_with_cidr_blocks | if write only runs ingress_with_cidr_blocks , and silentaly skip ingress_rules | inside module has internal logic for high priority for ingress_with_cidr_blocks.

    ingress_with_cidr_blocks = [
        {
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = "0.0.0.0/0"
            description = "Allow ssh" 
        },
        {
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = "0.0.0.0/0"
            description = "Allow http" 
        },
        {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = "0.0.0.0/0"
            description = "Allow https" 
        }
    ]

    egress_rules = ["all-all"]

    tags = {
        Name        = "${var.environment}-my-sg"
        Terraform   = "true"
        Environment = var.environment
        created_by  = var.created_by_user
    }
}


# key_pair.tf file content -----------------------------
resource "aws_key_pair" "my-key-pair" {
    key_name = "${var.environment}-my-practice-key"
    public_key = file("my-practice-key.pub")

    tags = {
        Name        = "${var.environment}-my-practice-key"
        Terraform   = "true"
        Environment = var.environment
        created_by  = var.created_by_user
    }
}

# ec2.tf file content ------------------------------------

resource "aws_instance" "my-aws-instance" {

    ami = var.ami_id
    instance_type = var.instance_type

    vpc_security_group_ids = [ module.my-sg.security_group_id ]
    subnet_id = module.my_vpc.public_subnets[0]

    key_name = aws_key_pair.my-key-pair.key_name

    

    root_block_device {
      volume_size = 20
      volume_type = "gp3"
      delete_on_termination = true
    }
    user_data = file("nginx_install.sh")

    tags = {
        Name        = "${var.environment}-my-instance"
        Terraform   = "true"
        Environment = var.environment
        created_by  = var.created_by_user
    }
}


# outputs.tf file content ---------------------

output "instance_public_ip" {
    value = aws_instance.my-aws-instance.public_ip
}

output "instance_private_ip" {
    value = aws_instance.my-aws-instance.private_ip
}

output "instance_public_dns" {
    value = aws_instance.my-aws-instance.public_dns
}

output "vpc_name" {
    value = module.my_vpc.name
}

output "security_group" {
    value = module.my-sg.security_group_name 
}

output "region" {
    value = var.aws_region
}

output "environment" {
    value = var.environment
}
output "ami_id" {
    value = var.ami_id
}

output "instance_type" {
    value = var.instance_type
}
output "created_by" {
    value = var.created_by_user
}


provider "aws" {
  region = var.region
}

terraform {
  required_version = "> 0.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.44"
    }
  }

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

data "aws_availability_zones" "available" {}

locals {
  module = "network"

  # Automated cidr creation using the logic in the following post -> https://aws.amazon.com/blogs/startups/practical-vpc-design/
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names

  az_count = length(local.availability_zones)

  az_reserved_bits = ceil(log(local.az_count, 2))

  az_cidr_list = [
    for az in local.availability_zones :
    cidrsubnet(var.cidr, local.az_reserved_bits, index(local.availability_zones, az))
  ]

  private_subnets = [
    for az_cidr in local.az_cidr_list : cidrsubnet(az_cidr, 1, 0)
  ]

  public_subnets = [
    for az_cidr in local.az_cidr_list : cidrsubnet(cidrsubnet(az_cidr, 1, 1), 1, 0)
  ]
}

module "label" {
  source = "../../child-modules/label"
  module = local.module
  app    = var.app
  stage  = var.stage
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.1.0"

  name = module.label.name

  cidr = var.cidr

  azs             = local.availability_zones
  private_subnets = local.private_subnets

  public_subnets = local.public_subnets

  create_database_subnet_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = var.stage != "prod"

  enable_dhcp_options              = true
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  tags = merge(module.label.tags, { "kubernetes.io/cluster/${module.label.name}" = "shared" })

  private_subnet_tags = module.label.tags

  public_subnet_tags = module.label.tags
}

module "bucket" {
  source  = "../../child-modules/bucket"
  
  app   = var.app
  stage = var.stage
}
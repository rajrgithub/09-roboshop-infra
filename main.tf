
module "vpc" {
  source         = "github.com/rajrgithub/10-tf-module-vpc"
  env= var.env
  default_vpc_id = var.default_vpc_id

  for_each     = var.vpc
  cidr_block   = each.value.cidr_block
}

module "subnets" {
  source         = "github.com/rajrgithub/11-tf-module-subnets"
  env= var.env
  default_vpc_id = var.default_vpc_id

  vpc_id = module.vpc.vpc_id

  for_each     = var.subnets
  cidr_block   = each.value.cidr_block
  availability_zone = each.value.availability_zone
  name = each.value.name
}

output "vpc_id" {
  value = "module.vpc"
}
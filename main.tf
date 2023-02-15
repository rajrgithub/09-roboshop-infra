
module "network" {
  source         = "github.com/rajrgithub/10-tf-module-vpc"
  env= var.env
  default_vpc_id = var.default_vpc_id

  for_each     = var.vpc
  cidr_block   = each.value.cidr_block
}


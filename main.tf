#resource "null_resource" "test" {
#  provisioner "local-exec" {
#    command = "echo ${var.env}"
#  }
#}

module "network" {
  source         = "github.com/rajrgithub/10-tf-module-vpc"
  env= var.env
  default_vpc_id = var.default_vpc_id

  for_each     = var.vpc
  cidr_block   = each.value.cidr_block
 # subnets_cidr = each.value.subnets_cidr
  public_subnets_cidr  = each.value.public_subnets_cidr
  private_subnets_cidr = each.value.private_subnets_cidr
  availability_zones   = each.value.availability_zones
}


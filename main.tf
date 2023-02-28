module "vpc" {
  source         = "github.com/rajrgithub/10-tf-module-vpc"
  env            = var.env
  default_vpc_id = var.default_vpc_id

  for_each          = var.vpc
  cidr_block        = each.value.cidr_block
  public_subnets    = each.value.public_subnets
  private_subnets   = each.value.private_subnets
  availability_zone = each.value.availability_zone
}


module "docdb" {
  source = "github.com/rajrgithub/12-tf-module-docdb"
  env    = var.env

  for_each            = var.docdb
  subnet_ids          = lookup(lookup(lookup(lookup(module.vpc, each.value.vpc_name, null), "private_subnet_ids", null), each.value.subnets_name, null), "subnet_ids", null)
  vpc_id              = lookup(lookup(module.vpc, each.value.vpc_name, null), "vpc_id", null)
  allow_cidr          = lookup(lookup(lookup(lookup(var.vpc, each.value.vpc_name, null), "private_subnets", null), "app", null), "cidr_block", null)
  engine_version      = each.value.engine_version
  number_of_instances = each.value.number_of_instances
  instance_class      = each.value.instance_class
}

module "rds" {
  source = "github.com/rajrgithub/13-tf-module-rds"
  env    = var.env

  for_each            = var.rds
  subnet_ids          = lookup(lookup(lookup(lookup(module.vpc, each.value.vpc_name, null), "private_subnet_ids", null), each.value.subnets_name, null), "subnet_ids", null)
  vpc_id              = lookup(lookup(module.vpc, each.value.vpc_name, null), "vpc_id", null)
  allow_cidr          = lookup(lookup(lookup(lookup(var.vpc, each.value.vpc_name, null), "private_subnets", null), "app", null), "cidr_block", null)
  engine              = each.value.engine
  engine_version      = each.value.engine_version
  number_of_instances = each.value.number_of_instances
  instance_class      = each.value.instance_class
}


module "elasticache" {
  source = "github.com/rajrgithub/14-tf-module-elasticache"
  env    = var.env

  for_each        = var.elasticache
  subnet_ids      = lookup(lookup(lookup(lookup(module.vpc, each.value.vpc_name, null), "private_subnet_ids", null), each.value.subnets_name, null), "subnet_ids", null)
  vpc_id          = lookup(lookup(module.vpc, each.value.vpc_name, null), "vpc_id", null)
  allow_cidr      = lookup(lookup(lookup(lookup(var.vpc, each.value.vpc_name, null), "private_subnets", null), "app", null), "cidr_block", null)
  num_cache_nodes = each.value.num_cache_nodes
  node_type       = each.value.node_type
  engine_version  = each.value.engine_version
}

module "rabbitmq" {
  source = "github.com/rajrgithub/15-tf-module-rabbitmq"
  env    = var.env
  bastion_cidr = var.bastion_cidr

  for_each           = var.rabbitmq
  subnet_ids         = lookup(lookup(lookup(lookup(module.vpc, each.value.vpc_name, null), "private_subnet_ids", null), each.value.subnets_name, null), "subnet_ids", null)
  vpc_id             = lookup(lookup(module.vpc, each.value.vpc_name, null), "vpc_id", null)
  allow_cidr         = lookup(lookup(lookup(lookup(var.vpc, each.value.vpc_name, null), "private_subnets", null), "app", null), "cidr_block", null)
  engine_type        = each.value.engine_type
  engine_version     = each.value.engine_version
  host_instance_type = each.value.host_instance_type
  deployment_mode    = each.value.deployment_mode
}

module "alb" {
  source = "github.com/rajrgithub/17-tf-module-alb"
  env    = var.env

  for_each     = var.alb
  subnet_ids   = lookup(lookup(lookup(lookup(module.vpc, each.value.vpc_name, null), each.value.subnets_type, null), each.value.subnets_name, null), "subnet_ids", null)
  vpc_id       = lookup(lookup(module.vpc, each.value.vpc_name, null), "vpc_id", null)
  #allow_cidr   = lookup(lookup(lookup(lookup(var.vpc, each.value.vpc_name, null), "private_subnets", null), "app", null), "cidr_block", null)
  allow_cidr   = each.value.internal ? lookup(lookup(lookup(lookup(var.vpc, each.value.vpc_name, null), "private_subnets", null), "web", null), "cidr_block", null) : ["0.0.0.0/0"]
  subnets_name = each.value.subnets_name
  internal     = each.value.internal
}

module "apps" {
  source = "github.com/rajrgithub/16-tf-module-app"
  env    = var.env

  # app trying to connect even before DB is creating
  depends_on = [module.docdb, module.rds, module.rabbitmq, module.alb, module.rds, module.elasticache]

  for_each         = var.apps
  subnet_ids       = lookup(lookup(lookup(lookup(module.vpc, each.value.vpc_name, null), each.value.subnets_type, null), each.value.subnets_name, null), "subnet_ids", null)
  vpc_id           = lookup(lookup(module.vpc, each.value.vpc_name, null), "vpc_id", null)
  allow_cidr       = lookup(lookup(lookup(lookup(var.vpc, each.value.vpc_name, null), each.value.allow_cidr_subnets_type, null), each.value.allow_cidr_subnets_name, null), "cidr_block", null)
  alb              = lookup(lookup(module.alb, each.value.alb, null), "dns_name", null)
  listener          = lookup(lookup(module.alb, each.value.alb, null), "listener", null)
  alb_arn           = lookup(lookup(module.alb, each.value.alb, null), "alb_arn", null)
  component        = each.value.component
  app_port         = each.value.app_port
  max_size         = each.value.max_size
  min_size         = each.value.min_size
  desired_capacity = each.value.desired_capacity
  instance_type    = each.value.instance_type
  bastion_cidr     = var.bastion_cidr
  listener_priority = each.value.listener_priority

}

//output "vpc" {
//  value = lookup(lookup(lookup(lookup(module.vpc, "main", null), "public_subnets", null), "public", null), "subnet_ids", null)
//}

#output "rds"{
#  value=module.rds
#  sensitive=true
#}

output "alb" {
  value = module.alb
}
locals {
  lb_ingress_subnets = length(var.lb_ingress_subnets) != 0 ? var.lb_ingress_subnets : ["0.0.0.0/0"]
  name               = replace(var.name, ".", "-")
  subnets = {
    for k, v in var.vpc["subnets"] :
    v.availability_zone => {
      cidr_block              = v.cidr_block
      map_public_ip_on_launch = v.map_public_ip_on_launch
      tags                    = v.tags
    }
  }
  user_data = {
    cluster_name = "${local.name}-cluster"
  }
}
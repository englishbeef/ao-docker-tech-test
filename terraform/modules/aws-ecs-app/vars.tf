variable "ec2" {
  default = {
    associate_public_ip_address = true
    desired_capacity            = 2
    health_check_grace_period   = 300
    instance_type               = "t2.micro"
    max_size                    = 4
    min_size                    = 2
  }
  description = "Configuraiton for the underlying EC2 instances"
  type = object({
    associate_public_ip_address = bool
    desired_capacity            = number
    health_check_grace_period   = number
    instance_type               = string
    max_size                    = number
    min_size                    = number
  })
}

variable "lb_ingress_subnets" {
  default     = []
  description = "A list of subnets allowed to access the application. Will override 0.0.0.0/0 default"
  type        = list(string)
}

variable "name" {
  description = "The name of the application being deployed"
  type        = string
}

variable "priviledged_subnets" {
  default     = []
  description = "Subnets that are allowed SSH access to the EC2 instances"
  type        = list(string)
}

variable "public_key" {
  description = "Public SSH key to deploy to the EC2 instances"
  type        = string
}

variable "service" {
  description = "Configuration for the service being deployed"
  type = object({
    container_definitions              = string
    deployment_maximum_percent         = number
    deployment_minimum_healthy_percent = number
    desired_count                      = number
    load_balancer = object({
      container_name = string
      container_port = number
      protocol       = string
    })
  })
}

variable "ssl_policy" {
  default     = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  description = "The SSL Policy to use on the loadbalancers HTTPS endpoint"
  type        = string
}

variable "vpc" {
  default = {
    super_cidr = "10.0.0.0/25"
    subnets = [
      {
        availability_zone = "eu-west-2a"
        cidr_block        = "10.0.0.0/27"
      },
      {
        availability_zone = "eu-west-2b"
        cidr_block        = "10.0.0.32/27"
      },
      {
        availability_zone = "eu-west-2c"
        cidr_block        = "10.0.0.64/27"
      },
    ]
  }
  description = "Attributes describing the underlaying VPC"
  type = object({
    super_cidr = string
    subnets = list(object({
      availability_zone       = string
      cidr_block              = string
      map_public_ip_on_launch = optional(bool)
      tags                    = optional(map(string))
    }))
  })
}
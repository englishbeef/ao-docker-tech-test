provider "aws" {
  access_key = var.aws_access_key
  region     = var.aws_region
  secret_key = var.aws_secret_key
}

module "aws-ecs-app" {
  source = "../../modules/aws-ecs-app"

  name = "englishbeef.net"
  priviledged_subnets = [
    "212.159.53.112/29",
    "212.159.25.240/29",
  ]
  public_key = file("~/.ssh/id_rsa.pub")
  service = {
    container_definitions              = file("./task.json")
    deployment_maximum_percent         = 200
    deployment_minimum_healthy_percent = 100
    desired_count         = 1
    load_balancer = {
      container_name = "nginx"
      container_port = 80
      protocol       = "HTTP"
    }
  }
}

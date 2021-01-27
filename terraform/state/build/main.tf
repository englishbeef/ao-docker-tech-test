provider "aws" {
  access_key = var.aws_access_key
  region     = var.aws_region
  secret_key = var.aws_secret_key
}

module "aws-ec2-build-docker" {
  source = "../../modules/aws-ec2-build-docker"

  priviledged_subnets = [
    "212.159.53.112/29",
    "212.159.25.240/29",
  ]
  public_key = file("~/.ssh/id_rsa.pub")
}

output "build_ip" {
  value = module.aws-ec2-build-docker.instance[0].public_ip
}

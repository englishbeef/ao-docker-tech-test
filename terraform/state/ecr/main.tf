provider "aws" {
  access_key = var.aws_access_key
  region     = var.aws_region
  secret_key = var.aws_secret_key
}

module "aws-ecr" {
  source = "../../modules/aws-ecr"

  repositories = [
    { name = "aspnetapp" },
    { name = "nginx" },
  ]
}

output "repository_urls" {
  value = {
    for k, v in module.aws-ecr.registries[0] :
    "${k}" => v.repository_url
  }
}

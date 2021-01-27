resource "aws_ecr_repository" "default" {
  for_each = local.repositories

  image_tag_mutability = each.value["image_tag_mutability"]
  name                 = each.key

  encryption_configuration {
    encryption_type = each.value["encryption_type"]
  }

  image_scanning_configuration {
    scan_on_push = each.value["scan_on_push"]
  }
}

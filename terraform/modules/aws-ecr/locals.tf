locals {
  repositories_defaults = {
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
  }
  repositories = {
    for k, v in defaults(var.repositories, local.repositories_defaults) :
    v.name => {
      image_tag_mutability = v.image_tag_mutability
      scan_on_push         = v.scan_on_push
      encryption_type      = v.encryption_type
      kms_key              = v.kms_key
    }
  }
}

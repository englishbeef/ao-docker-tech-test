variable "repositories" {
  type = list(object({
    name                 = string
    image_tag_mutability = optional(string)
    scan_on_push         = optional(bool)
    encryption_type      = optional(string)
    kms_key              = optional(string)
  }))
}

variable "priviledged_subnets" {
  default     = []
  description = "Subnets that are allowed SSH access to the EC2 instance"
  type        = list(string)
}

variable "public_key" {
  description = "Public SSH key to deploy to the EC2 instances"
  type        = string
}

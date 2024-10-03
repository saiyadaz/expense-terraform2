terraform {
  backend "s3" {}
}

output "env" {
  value = var.env
}

variable "env" {}
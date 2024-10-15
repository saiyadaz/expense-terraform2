data "aws_ami" "ami" {
  most_recent = true
  name_regex  = "RHEL-9-DevOps-Practice"
  owners      = ["973714476881"]
}

data "aws_security_group" "selected" {
   id = var.security_group_id
}

data "vault_generic_secret" "ssh" {
  path = "common/common"
}

terraform {
  backend "s3" {
    bucket = "devops-tf-states-sz"
    key = "test/state"
    region = "us-east-1"
  }
}
resource "null_resource" "dummy1" {}
resource "null_resource" "dummy2" {}
resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.selected.id]

 tags = {
   Name= var.component
 }

}
resource "null_resource" "ansible" {
  provisioner "remote-exec" {

    connection {
      type = "ssh"
      user = var.ssh.user
      password = var.ssh.pass
      host = aws_instance.instance.public_ip
  }

    inline = [
      "sudo pip3.11 install ansible",
      "ansbile-pull -i localhost, -U https://github.com/saiyadaz/expense-ansible2.git expense.yml -e env=${var.env} -e role_name=${var.component}"
    ]
  }
}
resource "aws_route53_record" "record" {
  name    = "${var.component}-${var.env}"
  type    = "A"
  zone_id = var.zone_id
  records = [aws_instance.instance.private_ip]
  ttl = 30
}
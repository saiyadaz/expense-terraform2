resource "aws_security_group" "main" {
  name           = "${var.component}-${var.env}-sg"
  description    = "${var.component}-${var.env}-sg"
  vpc_id         =  var.vpc_id


  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"        #all traffic
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}


resource "aws_instance" "instance" {
  ami                     = data.aws_ami.ami.image_id
  instance_type           = var.instance_type
  vpc_security_group_ids  = [aws_security_group.main.id]
  subnet_id               = var.subnets[0]

 tags = {
   Name    = var.component
   monitor = "yes"

 }

}
resource "null_resource" "ansible" {
  triggers = {
    instance = aws_instance.instance.id
  }

    connection {
      type        = "ssh"
      user        = jsondecode(data.vault_generic_secret.ssh.data_json).ansible_user
      password    = jsondecode(data.vault_generic_secret.ssh.data_json).ansible_pass
      host        = aws_instance.instance.private_ip
 }
  provisioner "remote-exec" {
    inline = [
      "rm -f ~/*.json",
      "sudo pip3.11 install ansible hvac",
      "ansible-pull -i localhost, -U https://github.com/saiyadaz/expense-ansible2.git get-secrets.yml -e env=${var.env} -e role_name=${var.component} -e vault_token=${var.vault_token}",
      "ansible-pull -i localhost, -U https://github.com/saiyadaz/expense-ansible2.git expense.yml -e env=${var.env} -e role_name=${var.component} -e @~/secrets.json"
    ]
  }

  provisioner "remote-exec" {
     inline = [
       "rm -f ~/secrets.json ~/app.json"
     ]
     }
   }


resource "aws_route53_record" "record" {
  name    = "${var.component}-${var.env}"
  type    = "A"
  zone_id = var.zone_id
  records = [aws_instance.instance.private_ip]
  ttl = 3
}
resource "aws_security_group" "main" {
  name           = "${var.component}-${var.env}-sg"
  description    = "${var.component}-${var.env}-sg"
  vpc_id         =  var.vpc_id


  ingress {
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "TCP"
    cidr_blocks      = var.server_app_port_sg_cidr ##this is for main server related changes
    }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = var.bastion_nodes#32 is for only workstation node to be accessed
  }

  ingress {  #this is for prometheus node
    from_port        = 9100
    to_port          = 9100
    protocol         = "TCP"
    cidr_blocks      = var.prometheus_nodes
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
   env     = var.env

 }
 lifecycle {
   ignore_changes = [
   ami ]
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
resource "aws_route53_record" "server" {
  count   = var.lb_needed ? 0 : 1
  name    = "${var.component}-${var.env}"
  type    = "A"
  zone_id = var.zone_id
  records = [aws_instance.instance.private_ip]
  ttl = 30
}


resource "aws_route53_record" "load-balancer" {
  count   = var.lb_needed ? 1 : 0
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  zone_id = var.zone_id
  records = [aws_lb.main[0].dns_name]
  ttl = 30
}
resource "aws_security_group" "load-balancer" {
 count           = var.lb_needed ? 1 : 0
  name           = "${var.component}-${var.env}-lb-sg"
  description    = "${var.component}-${var.env}-lb-sg"
  vpc_id         =  var.vpc_id


  ingress {
    from_port        = var.app_port #load balancer to allow access and now to whom to allow answer
    to_port          = var.app_port
    protocol         = "TCP"
    cidr_blocks      = var.lb_app_port_sg_cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"        #all traffic
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  count               = var.lb_needed ? 1 : 0
  name                = "${var.component}-${var.env}-alb"
  internal            = var.lb_type =="public"? false : true
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.load-balancer[0].id]
  subnets              = var.lb_subnets
#[0]--denotes list ##
  tags = {
    Environment = "${var.component}-${var.env}-alb"
  }
}

resource "aws_lb_target_group" "main" {
  count                = var.lb_needed ? 1 : 0
  name                 = "${var.component}-${var.env}-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 15

  health_check {
    healthy_threshold   = 2
    interval            = 5
    path                = "/health"
    port                = var.app_port
    timeout             = 2
    unhealthy_threshold = 2
  }

}


resource "aws_lb_target_group_attachment" "main" {
  count            = var.lb_needed ? 1 : 0
  target_group_arn = aws_lb_target_group.main[0].arn
  target_id        = aws_instance.instance.id
  port             = var.app_port
}

resource "aws_lb_listener" "frontend-http" {
  count             = var.lb_needed && var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = "443"
      portocol = "HTTPS"
      status_code = "HTTP_301"
    }


    }

}

resource "aws_lb_listener" "frontend-https" {
  count             = var.lb_needed && var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPs"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn    = var.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group[0].main.arn

  }

}
resource "aws_lb_listener" "backend" {
  count             = var.lb_needed && var.component != "public" ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}
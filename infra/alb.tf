resource "aws_security_group" "alb_sg" {
  name = "parking-management-alb-sg"
  description = "Security group for ALB"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "parking-management-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_sg_rule_inbound_http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_sg_rule_inbound_https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_sg_rule_outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_alb" "main" {
  name = "parking-management-alb"
  internal = false # falseにすると、インターネットに公開される(VPC外からアクセス可能=>CloudFrontからのアクセスできるようになる)
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1c.id]
  tags = {
    Name = "parking-management-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name = "parking-management-alb-tg"
  port = 80 # Nginxのポート
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id

  health_check {
    path = "/up"
    port = 80 # Nginxのポート
    protocol = "HTTP"
    interval = 30
    timeout = 20
    healthy_threshold = 5
    unhealthy_threshold = 2
  }
  tags = {
    Name = "parking-management-alb-tg"
  }

}

# ターゲットグループとEC2を紐づける
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id = aws_instance.app_1a.id
  port = 80 # ALBが、EC2の80ポートに流す(Nginx)
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect" # HTTPからHTTPSへリダイレクトする
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.main.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = aws_acm_certificate.main.arn # ACM証明書を紐づける
    default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = <<EOT
        <html>
        <head><title>503</title></head>
        <body>
        <center><h1>503</h1></center>
        </body>
        </html>
      EOT
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_rule" "https_to_app" {
  listener_arn = aws_lb_listener.https.arn

  priority = 10
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
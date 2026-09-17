# -------------------------------------------------------------
# 1. Data Sources
# -------------------------------------------------------------

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "public_a" {
  vpc_id     = data.aws_vpc.this.id
  cidr_block = var.public_subnet_a_cidr
}

data "aws_subnet" "public_b" {
  vpc_id     = data.aws_vpc.this.id
  cidr_block = var.public_subnet_b_cidr
}

data "aws_subnet" "private_a" {
  vpc_id     = data.aws_vpc.this.id
  cidr_block = var.private_subnet_a_cidr
}

data "aws_subnet" "private_b" {
  vpc_id     = data.aws_vpc.this.id
  cidr_block = var.private_subnet_b_cidr
}

data "aws_security_group" "ec2_ssh" {
  vpc_id = data.aws_vpc.this.id
  name   = var.ec2_sg_name
}

data "aws_security_group" "ec2_http" {
  vpc_id = data.aws_vpc.this.id
  name   = var.http_sg_name
}

data "aws_security_group" "alb" {
  vpc_id = data.aws_vpc.this.id
  name   = var.alb_sg_name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# -------------------------------------------------------------
# 2. Launch Template
# -------------------------------------------------------------

resource "aws_launch_template" "this" {
  name          = var.launch_template_name
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = var.key_pair_name

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    delete_on_termination = true
    security_groups = [
      data.aws_security_group.ec2_ssh.id,
      data.aws_security_group.ec2_http.id
    ]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf install -y httpd jq || true
              systemctl enable --now httpd

              TOKEN=$(curl -s -S -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -s -S -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
              PRIVATE_IP=$(curl -s -S -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

              echo "Instance ID: $INSTANCE_ID | Private IP: $PRIVATE_IP" > /var/www/html/index.html
              EOF
  )

  tags = var.common_tags

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name = "${var.project_id}-instance"
      }
    )
  }
}

# -------------------------------------------------------------
# 3. Application Load Balancer & Target Group
# -------------------------------------------------------------

resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id
  ]

  tags = var.common_tags
}

resource "aws_lb_target_group" "this" {
  name     = "${var.project_id}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.this.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = var.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# -------------------------------------------------------------
# 4. Auto Scaling Group
# -------------------------------------------------------------

resource "aws_autoscaling_group" "this" {
  name             = var.asg_name
  desired_capacity = 2
  min_size         = 1
  max_size         = 2
  vpc_zone_identifier = [
    data.aws_subnet.private_a.id,
    data.aws_subnet.private_b.id
  ]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_id
    propagate_at_launch = true
  }
}

# -------------------------------------------------------------
# 5. Attachment
# -------------------------------------------------------------

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  lb_target_group_arn    = aws_lb_target_group.this.arn
}
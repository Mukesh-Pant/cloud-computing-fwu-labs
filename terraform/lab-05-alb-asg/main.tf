# ----------------------------------------------------------------------------
# Self-contained VPC for Lab 5 (ALB requires 2 public subnets in different AZs)
# ----------------------------------------------------------------------------

resource "aws_vpc" "alb" {
  cidr_block           = "10.40.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "vpc-${var.suffix}-alb" }
}

resource "aws_internet_gateway" "alb" {
  vpc_id = aws_vpc.alb.id
  tags   = { Name = "igw-${var.suffix}-alb" }
}

resource "aws_subnet" "a" {
  vpc_id                  = aws_vpc.alb.id
  cidr_block              = "10.40.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "subnet-${var.suffix}-alb-a" }
}

resource "aws_subnet" "b" {
  vpc_id                  = aws_vpc.alb.id
  cidr_block              = "10.40.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "subnet-${var.suffix}-alb-b" }
}

resource "aws_route_table" "alb" {
  vpc_id = aws_vpc.alb.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.alb.id
  }

  tags = { Name = "rt-${var.suffix}-alb-public" }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.a.id
  route_table_id = aws_route_table.alb.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.b.id
  route_table_id = aws_route_table.alb.id
}

# ----------------------------------------------------------------------------
# Security group (allow HTTP from anywhere, all egress)
# ----------------------------------------------------------------------------

resource "aws_security_group" "web" {
  name        = "${var.suffix}-alb-web-sg"
  description = "Allow HTTP from anywhere for ALB demo"
  vpc_id      = aws_vpc.alb.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.suffix}-alb-web-sg" }
}

# ----------------------------------------------------------------------------
# Launch template + Auto Scaling Group
# ----------------------------------------------------------------------------

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "lt-${var.suffix}-"
  image_id      = data.aws_ami.al2023.id
  instance_type = "t2.micro"
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    display_name = var.display_name
    roll_number  = var.roll_number
  }))
  vpc_security_group_ids = [aws_security_group.web.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ec2-${var.suffix}-asg"
    }
  }
}

# ----------------------------------------------------------------------------
# Application Load Balancer + Target Group + Listener
# ----------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "alb-${var.suffix}"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.a.id, aws_subnet.b.id]

  tags = { Name = "alb-${var.suffix}" }
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-${var.suffix}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.alb.id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "tg-${var.suffix}" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "asg-${var.suffix}"
  min_size                  = 2
  max_size                  = 3
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.a.id, aws_subnet.b.id]
  target_group_arns         = [aws_lb_target_group.tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ec2-${var.suffix}-asg"
    propagate_at_launch = true
  }
}

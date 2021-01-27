resource "aws_acm_certificate" "default" {
  domain_name               = var.name
  subject_alternative_names = ["www.${var.name}"]
  validation_method         = "DNS"
}

resource "aws_autoscaling_group" "default" {
  desired_capacity          = var.ec2["desired_capacity"]
  health_check_grace_period = var.ec2["health_check_grace_period"]
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.default.name
  max_size                  = var.ec2["max_size"]
  min_size                  = var.ec2["min_size"]
  name                      = "${local.name}-asg"
  vpc_zone_identifier       = [for k, v in local.subnets : aws_subnet.default[k].id]
}

resource "aws_ecs_cluster" "default" {
  name = "${local.name}-cluster"
}

resource "aws_ecs_service" "default" {
  cluster                            = aws_ecs_cluster.default.arn
  depends_on                         = [aws_lb_listener.default]
  deployment_maximum_percent         = var.service["deployment_maximum_percent"]
  deployment_minimum_healthy_percent = var.service["deployment_minimum_healthy_percent"]
  desired_count                      = var.service["desired_count"]
  launch_type                        = "EC2"
  name                               = "${local.name}-service"
  task_definition                    = aws_ecs_task_definition.default.arn

  load_balancer {
    container_name   = var.service["load_balancer"]["container_name"]
    container_port   = var.service["load_balancer"]["container_port"]
    target_group_arn = aws_lb_target_group.default.arn
  }
}

resource "aws_ecs_task_definition" "default" {
  container_definitions    = var.service["container_definitions"]
  family                   = "${local.name}-task"
  requires_compatibilities = ["EC2"]
}

resource "aws_iam_instance_profile" "default" {
  name = "${local.name}-ecs-instance-profile"
  path = "/"
  role = aws_iam_role.default.id
}

resource "aws_iam_role" "default" {
  name               = "${local.name}-ecs-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_key_pair" "default" {
  key_name   = "${local.name}-ssh-key"
  public_key = var.public_key
}

resource "aws_launch_configuration" "default" {
  associate_public_ip_address = var.ec2["associate_public_ip_address"]
  depends_on                  = [aws_ecs_cluster.default]
  name_prefix                 = "${local.name}-"
  iam_instance_profile        = aws_iam_instance_profile.default.name
  image_id                    = data.aws_ami.default.id
  instance_type               = var.ec2["instance_type"]
  key_name                    = aws_key_pair.default.key_name
  security_groups             = [aws_security_group.instance.id]
  user_data                   = templatefile("${path.module}/cloud-init.cfg", local.user_data)

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data]
  }
}

resource "aws_lb" "default" {
  internal           = false
  load_balancer_type = "application"
  name               = local.name
  security_groups    = [aws_security_group.lb.id]
  subnets            = [for k, v in local.subnets : aws_subnet.default[k].id]
}

resource "aws_lb_listener" "default" {
  certificate_arn   = aws_acm_certificate.default.arn
  load_balancer_arn = aws_lb.default.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy

  default_action {
    target_group_arn = aws_lb_target_group.default.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.default.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "default" {
  name        = "${local.name}-lb-target"
  port        = var.service["load_balancer"]["container_port"]
  protocol    = var.service["load_balancer"]["protocol"]
  vpc_id      = aws_vpc.default.id
  target_type = "instance"
}

resource "aws_route53_record" "default" {
  name    = ""
  type    = "A"
  zone_id = data.aws_route53_zone.default.zone_id

  alias {
    name                   = aws_lb.default.dns_name
    zone_id                = aws_lb.default.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dns_validation" {
  for_each = {
    for i in aws_acm_certificate.default.domain_validation_options :
    i.domain_name => {
      name   = i.resource_record_name
      record = i.resource_record_value
      type   = i.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value["name"]
  records         = [each.value["record"]]
  ttl             = 60
  type            = each.value["type"]
  zone_id         = data.aws_route53_zone.default.zone_id
}

resource "aws_route53_record" "www" {
  name    = "www"
  records = [var.name]
  ttl     = "60"
  type    = "CNAME"
  zone_id = data.aws_route53_zone.default.zone_id
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

resource "aws_route_table_association" "default" {
  for_each = local.subnets

  route_table_id = aws_route_table.default.id
  subnet_id      = aws_subnet.default[each.key].id
}

resource "aws_security_group" "instance" {
  description = "${local.name}-instance security group rules"
  name        = "${local.name}-instance"
  vpc_id      = aws_vpc.default.id

  ingress {
    cidr_blocks = var.priviledged_subnets
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  ingress {
    cidr_blocks = [aws_vpc.default.cidr_block]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_security_group" "lb" {
  name        = "${local.name}-lb"
  description = "${local.name}-lb security group rules"
  vpc_id      = aws_vpc.default.id

  ingress {
    cidr_blocks = local.lb_ingress_subnets
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }

  ingress {
    cidr_blocks = local.lb_ingress_subnets
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_subnet" "default" {
  for_each = local.subnets

  availability_zone       = each.key
  cidr_block              = each.value["cidr_block"]
  map_public_ip_on_launch = each.value["map_public_ip_on_launch"]
  vpc_id                  = aws_vpc.default.id
  tags                    = each.value["tags"]
}

resource "aws_vpc" "default" {
  cidr_block = var.vpc["super_cidr"]
}

resource "aws_iam_instance_profile" "default" {
  name_prefix = "docker-build-"
  path        = "/"
  role        = aws_iam_role.default.id
}

resource "aws_iam_role" "default" {
  name_prefix        = "docker-build-"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_instance" "default" {
  associate_public_ip_address = true
  ami                         = data.aws_ami.default.id
  iam_instance_profile        = aws_iam_instance_profile.default.name
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.default.key_name
  security_groups             = [aws_security_group.default.name]
  user_data = templatefile("${path.module}/user-data.cfg", {})
}

resource "aws_key_pair" "default" {
  key_name_prefix = "docker-build-"
  public_key      = var.public_key
}

resource "aws_security_group" "default" {
  name_prefix = "docker-build-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    cidr_blocks = var.priviledged_subnets
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}
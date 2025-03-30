resource "aws_iam_role" "windows_ssm_role" {
  name = "lab-eks-windows-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.windows_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "windows_sg" {
  name        = "lab-eks-windows-sg"
  description = "Security group for Windows instance (no inbound public access)"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

resource "aws_iam_instance_profile" "windows_ssm_profile" {
  name = "lab-eks-windows-ssm-profile"
  role = aws_iam_role.windows_ssm_role.name
}

resource "aws_instance" "windows" {
  ami                         = data.aws_ami.windows.id
  instance_type               = "t3.medium"
  subnet_id                   = var.private_subnets[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.windows_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.windows_ssm_profile.name

  tags = {
    Name = "lab-eks-windows"
  }
}
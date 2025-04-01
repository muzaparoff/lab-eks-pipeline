resource "aws_db_subnet_group" "this" {
  name       = "lab-eks-rds-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "lab-eks-rds-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "lab-eks-rds-sg"
  description = "Security group for RDS, restrict access to backend only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL access from backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.backend_sg_id]  # Only allow access from backend security group
  }

  egress {
    description = "Allow outbound traffic to VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.10.0.0/16"]
  }

  tags = {
    Name = "lab-eks-rds-sg"
  }
}

resource "aws_db_instance" "this" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.6"
  instance_class         = "db.t4g.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  storage_type           = "gp2"
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = "lab-eks-rds"
  }
}
resource "aws_db_subnet_group" "this" {
  name       = "lab-eks-rds-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "lab-eks-rds-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "lab-eks-rds-sg"
  description = "Security group for RDS, restrict access to VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow DB access from within VPC"
    from_port   = var.db_engine == "postgres" ? 5432 : 3306
    to_port     = var.db_engine == "postgres" ? 5432 : 3306
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lab-eks-rds-sg"
  }
}

resource "aws_db_instance" "this" {
  allocated_storage      = 20
  engine                 = var.db_engine
  engine_version         = var.db_engine == "postgres" ? "15.5" : "8.0"  # Updated to latest supported version
  instance_class         = "db.t4g.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = "lab-eks-rds"
  }
}
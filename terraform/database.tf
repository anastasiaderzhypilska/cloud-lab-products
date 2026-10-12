resource "aws_db_subnet_group" "main" {
  name       = "cloud-lab-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "cloud-lab-db-subnets"
  }
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

resource "aws_db_instance" "postgres" {
  identifier        = "cloud-lab-postgres"
  engine            = "postgres"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "products"
  username = "appuser"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false
  storage_encrypted   = true

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Project = "cloud-lab"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

resource "aws_security_group" "alb" {
  name_prefix = "cloud-lab-alb-"
  description = "Public HTTP access to ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "cloud-lab-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_out" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "ecs" {
  name_prefix = "cloud-lab-ecs-"
  description = "API access only from ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "cloud-lab-ecs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_api" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_out" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds" {
  name_prefix = "cloud-lab-rds-"
  description = "PostgreSQL access only from ECS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "cloud-lab-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

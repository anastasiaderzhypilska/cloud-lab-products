locals {
  database_url = "postgresql://${urlencode(aws_db_instance.postgres.username)}:${urlencode(var.db_password)}@${aws_db_instance.postgres.address}:5432/${aws_db_instance.postgres.db_name}"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "cloud-lab-products"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${aws_ecr_repository.api.repository_url}:v1"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DATABASE_URL"
          value = local.database_url
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = "eu-north-1"
          awslogs-stream-prefix = "api"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "cloud-lab-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_execution
  ]

  lifecycle {
    ignore_changes = [task_definition]
  }
}

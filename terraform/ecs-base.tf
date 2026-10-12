resource "aws_ecs_cluster" "main" {
  name = "cloud-lab-cluster"
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/cloud-lab-products"
  retention_in_days = 7
}

resource "aws_iam_role" "ecs_execution" {
  name = "cloud-lab-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

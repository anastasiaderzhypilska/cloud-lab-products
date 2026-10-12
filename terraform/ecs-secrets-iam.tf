resource "aws_iam_role_policy" "ecs_secrets" {
  name = "cloud-lab-read-database-secret"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = [
          aws_secretsmanager_secret.database_url.arn,
          aws_secretsmanager_secret.jwt.arn
        ]
      }
    ]
  })
}

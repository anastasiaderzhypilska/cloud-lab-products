resource "aws_iam_role_policy" "ecs_secrets" {
  name = "cloud-lab-read-database-secret"
  role = aws_iam_role.ecs_execution.id

  policy = file("${path.module}/ecs-secrets-policy.json")
}

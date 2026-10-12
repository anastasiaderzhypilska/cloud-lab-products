resource "aws_secretsmanager_secret" "database_url" {
  name        = "cloud-lab/database-url"
  description = "PostgreSQL connection URL for ECS API"

  lifecycle {
    ignore_changes = [
      recovery_window_in_days,
      force_overwrite_replica_secret
    ]
  }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id

  secret_string = "postgresql://${urlencode(aws_db_instance.postgres.username)}:${urlencode(var.db_password)}@${aws_db_instance.postgres.address}:5432/${aws_db_instance.postgres.db_name}"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "jwt" {
  name        = "cloud-lab/jwt-secret"
  description = "JWT signing key for ECS API"
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id     = aws_secretsmanager_secret.jwt.id
  secret_string = file("${path.module}/../.jwt_secret")

  lifecycle {
    ignore_changes = [secret_string]
  }
}

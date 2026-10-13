resource "terraform_data" "ecr_bootstrap" {
  triggers_replace = [
    aws_ecr_repository.api.repository_url
  ]

  provisioner "local-exec" {
    working_dir = "${path.module}/.."
    interpreter = ["/bin/bash", "-c"]

    environment = {
      AWS_PROFILE = "cloud-lab-admin"
      AWS_REGION  = "eu-north-1"
      ECR_URL     = aws_ecr_repository.api.repository_url
    }

    command = <<-EOT
      set -euo pipefail

      if aws ecr describe-images \
        --repository-name cloud-lab-products \
        --image-ids imageTag=v1 \
        --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "ECR image v1 already exists."
      else
        aws ecr get-login-password --region "$AWS_REGION" |
          docker login --username AWS --password-stdin \
          "$${ECR_URL%/*}"

        docker build -t "$ECR_URL:v1" .
        docker push "$ECR_URL:v1"
      fi
    EOT
  }
}

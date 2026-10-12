resource "aws_ecr_repository" "api" {
  name                 = "cloud-lab-products"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "cloud-lab"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}

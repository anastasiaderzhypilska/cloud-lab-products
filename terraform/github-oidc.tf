resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "cloud-lab-github-actions"

  assume_role_policy = file("${path.module}/../github-oidc-trust.json")
}

resource "aws_iam_role_policy" "github_actions" {
  name = "cloud-lab-deploy"
  role = aws_iam_role.github_actions.id

  policy = file("${path.module}/../github-actions-policy.json")
}

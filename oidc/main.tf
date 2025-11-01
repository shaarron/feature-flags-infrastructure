
# GitHub OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] 
}


resource "aws_iam_role" "gha_oidc_role" {
  name = "gha-oidc-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:shaarron/feature-flags-app:ref:refs/heads/main"
        }
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "gha_power" {
  role       = aws_iam_role.gha_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "travelease-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:fatemehfeizipour@252370047/travelease-serverless-contact-form-rebuild@1423875969:*"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "github_read_only" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "github_state_lock" {
  name = "state-lock"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::travelease-contact-form-state/travelease/terraform.tfstate.tflock"
      }
    ]
  })
}

resource "aws_iam_role" "github_apply" {
  name = "travelease-github-apply-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:fatemehfeizipour@252370047/travelease-serverless-contact-form-rebuild@1423875969:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_iam" {
  role = aws_iam_role.github_apply.id
  name = "apply-iam"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iam:CreateRole", "iam:GetRole", "iam:UpdateRole", "iam:DeleteRole", "iam:CreatePolicy", "iam:GetPolicy", "iam:DeletePolicy", "iam:CreatePolicyVersion"]
        Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/travelease-*", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/travelease-*"]
      }
    ]
  })


}
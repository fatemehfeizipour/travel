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

resource "aws_iam_role_policy" "github_apply_state" {
  name = "apply-state"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::travelease-contact-form-state"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "arn:aws:s3:::travelease-contact-form-state/travelease/terraform.tfstate",
          "arn:aws:s3:::travelease-contact-form-state/travelease/terraform.tfstate.tflock"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_dynamodb" {
  name = "apply-dynamodb"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:*"]
        Resource = aws_dynamodb_table.contact_submissions.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_lambda" {
  name = "apply-lambda"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:*"]
        Resource = aws_lambda_function.lambda_function.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_sns" {
  name = "apply-sns"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sns:*"]
        Resource = [
          aws_sns_topic.new_submission_notification.arn,
          "${aws_sns_topic.new_submission_notification.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_ses" {
  name = "apply-ses"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ses:*"]
        Resource = [
          aws_ses_email_identity.ses_sender.arn,
          aws_ses_email_identity.ses_recipient.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_cloudwatch" {
  name = "apply-cloudwatch"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:*"]
        Resource = [
          aws_cloudwatch_log_group.log_group.arn,
          "${aws_cloudwatch_log_group.log_group.arn}:*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:*"]
        Resource = aws_cloudwatch_metric_alarm.contact_form_failures.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_website_bucket" {
  name = "apply-website-bucket"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          aws_s3_bucket.host_bucket.arn,
          "${aws_s3_bucket.host_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_apigateway" {
  name = "apply-apigateway"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["apigateway:*"]
        Resource = [
          "arn:aws:apigateway:ca-central-1::/apis",
          "arn:aws:apigateway:ca-central-1::/apis/*",
          "arn:aws:apigateway:ca-central-1::/tags/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_cloudfront" {
  name = "apply-cloudfront"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["cloudfront:*"]
        Resource = [
          aws_cloudfront_distribution.website.arn,
          aws_cloudfront_origin_access_control.website_oac.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_apply_iam_extra" {
  name = "apply-iam-extra"
  role = aws_iam_role.github_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListPolicyVersions",
          "iam:GetPolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/travelease-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/travelease-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider"
        ]
        Resource = aws_iam_openid_connect_provider.github.arn
      }
    ]
  })
}
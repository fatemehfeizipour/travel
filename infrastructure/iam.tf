resource "aws_iam_role" "lambda_role" {
  name = "travelease-lambda-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "Lambda-IAM-Role"
  }
}


resource "aws_iam_policy" "permission_policy" {
  name        = "lambda_permission_policy"
  path        = "/"
  description = "policy for lambda"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.contact_submissions.arn
      },

      
        {
          Action = [
            "sns:Publish",
          ]
          Effect   = "Allow"
          Resource = aws_sns_topic.new_submission_notification.arn
        },
      
      
      #   {
      #     Action = [
      #       "ses:SendEmail",
      #     ]
      #     Effect   = "Allow"
      #     Resource = aws_dynamodb_table.contact_submissions.arn
      #   },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attached" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.permission_policy.arn
}
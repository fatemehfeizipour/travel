resource "aws_lambda_function" "lambda_function" {
  function_name    = "handle_contact_form_submission"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.14"
  filename         = data.archive_file.zipped_function_code.output_path
  source_code_hash = data.archive_file.zipped_function_code.output_base64sha256
  environment {
    variables = {
      TABLE_NAME   = aws_dynamodb_table.contact_submissions.name
      TOPIC_ARN    = aws_sns_topic.new_submission_notification.arn
      SENDER_EMAIL = var.sender_ses
    }
  }
}
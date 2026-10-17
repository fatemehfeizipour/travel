resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/handle_contact_form_submission"
  retention_in_days = 3

  tags = {
    project = "travelease-contact-rebuild"
  }
}
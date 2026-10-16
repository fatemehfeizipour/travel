resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/contact_form_log"
  retention_in_days = 3

  tags = {
    project = "travelease-contact-rebuild"
  }
}
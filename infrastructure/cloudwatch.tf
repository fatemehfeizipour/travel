resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/handle_contact_form_submission"
  retention_in_days = 3

  tags = {
    project = "travelease-contact-rebuild"
  }
}

resource "aws_cloudwatch_log_metric_filter" "failed_steps" {
  name           = "contact-form-failed-steps"
  pattern        = "\"failed\""
  log_group_name = aws_cloudwatch_log_group.log_group.name

  metric_transformation {
    name          = "ContactFormFailures"
    namespace     = "TravelEase"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "contact_form_failures" {
  alarm_name          = "contact-form-failures"
  alarm_description   = "A step in the contact form Lambda failed"
  namespace           = "TravelEase"
  metric_name         = "ContactFormFailures"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.new_submission_notification.arn]
}

resource "aws_cloudwatch_log_metric_filter" "honeypot_triggers" {
  name           = "contact-form-honeypot-triggers"
  pattern        = "\"honeypot trigger\""
  log_group_name = aws_cloudwatch_log_group.log_group.name

  metric_transformation {
    name          = "HoneypotTriggers"
    namespace     = "TravelEase"
    value         = "1"
    default_value = "0"
  }
}
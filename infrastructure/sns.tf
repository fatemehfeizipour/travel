
resource "aws_sns_topic" "new_submission_notification" {
  name = "new-submission-topic"
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.new_submission_notification.arn
  endpoint  = var.notification_email
  protocol  = "email"
}

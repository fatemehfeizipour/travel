resource "aws_ses_email_identity" "ses_sender" {
  email = var.sender_ses
}

resource "aws_ses_email_identity" "ses_recipient" {
  email = var.test_recipient
}
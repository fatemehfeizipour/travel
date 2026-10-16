variable "notification_email" {
  description = "send notification email to business"
  type        = string
}
variable "sender_ses" {
  description = "verified sender address for SES"
  type        = string
}
variable "test_recipient" {
  description = "recipient email address for test"
  type        = string
}
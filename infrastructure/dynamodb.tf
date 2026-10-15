resource "aws_dynamodb_table" "contact_submissions" {
  name         = "customer-form-submission-database"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "submission_id"

  attribute {
    name = "submission_id"
    type = "S"

  }

  point_in_time_recovery {
    enabled = false
  }
}
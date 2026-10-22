# Archive a single file.

data "archive_file" "zipped_function_code" {
  type             = "zip"
  source_file      = "../lambda/lambda_function.py"
  output_path      = "./function.zip"
  output_file_mode = "0666"
}

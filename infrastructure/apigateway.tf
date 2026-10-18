resource "aws_apigatewayv2_api" "travelease_api" {
  name          = "travelease-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
    allow_origins = ["https://${aws_cloudfront_distribution.website.domain_name}"]
  }

}

resource "aws_apigatewayv2_integration" "api_lambda_connection" {
  api_id             = aws_apigatewayv2_api.travelease_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_function.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.travelease_api.id
  route_key = "POST /contact"
  target    = "integrations/${aws_apigatewayv2_integration.api_lambda_connection.id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.travelease_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowMyAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_apigatewayv2_api.travelease_api.execution_arn}/*"
}
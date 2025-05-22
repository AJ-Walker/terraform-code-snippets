resource "aws_api_gateway_rest_api" "movies_api_gateway" {
  name = "movies_api_gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  binary_media_types = ["multipart/form-data"]

  tags = {
    Name        = "Movies REST API"
    Environment = "Dev"
  }
}

resource "aws_api_gateway_resource" "movies_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.movies_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.movies_api_gateway.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "movies_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.movies_api_gateway.id
  parent_id   = aws_api_gateway_resource.movies_api_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "movies_any_method" {
  rest_api_id   = aws_api_gateway_rest_api.movies_api_gateway.id
  resource_id   = aws_api_gateway_resource.movies_proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "movies_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.movies_api_gateway.id
  resource_id             = aws_api_gateway_resource.movies_proxy_resource.id
  http_method             = aws_api_gateway_method.movies_any_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.movies_api_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "movies_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.movies_api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.movies_api_resource.id,
      aws_api_gateway_resource.movies_proxy_resource.id,
      aws_api_gateway_method.movies_any_method.id,
      aws_api_gateway_integration.movies_lambda_integration.id,
      aws_api_gateway_rest_api.movies_api_gateway.binary_media_types
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "movies_api_dev_stage" {
  deployment_id = aws_api_gateway_deployment.movies_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.movies_api_gateway.id
  stage_name    = "dev"
}
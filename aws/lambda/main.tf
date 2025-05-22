module "global_config" {
  source = "../modules/global_config" # Relative path to your global module

  # You can pass values here if you want to override the default in the global module
  # aws_region = "ap-south-1"
}

provider "aws" {
  region = module.global_config.aws_region
}

resource "aws_lambda_function" "movies_api_lambda" {
  function_name = "movies_api_lambda"
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "provided.al2023"
  handler       = "main"
  filename      = "${path.module}/lambda_function_payload.zip"

  timeout = 180

  source_code_hash = data.archive_file.lambda.output_base64sha256
  environment {
    variables = {
      REGION = module.global_config.aws_region
    }
  }

  tags = {
    Name        = module.global_config.project_name
    Environment = module.global_config.environment
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_access_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_access_policy.arn
}

resource "aws_iam_policy" "lambda_access_policy" {
  name   = "lambda_dynamodb_policy"
  policy = data.aws_iam_policy_document.allow_lambda_access_policy_doc.json
}


resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.movies_api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.movies_api_gateway.execution_arn}/*"
}
# This module imports global configuration variables defined in a separate file.
module "global_config" {
  source = "../modules/global_config" # Relative path to your global module

  # You can pass values here if you want to override the default in the global module
  # aws_region = "ap-south-1"
}

# Configures the AWS provider.
# This block tells Terraform that we intend to manage resources within Amazon Web Services.
provider "aws" {
  region = module.global_config.aws_region # The AWS region to use this resource
}

# This resource creates an AWS Lambda function, a serverless compute service
# that runs code in response to events.
resource "aws_lambda_function" "movies_api_lambda" {
  function_name = "movies_api_lambda"                          # A unique name for the Lambda function.
  role          = aws_iam_role.lambda_execution_role.arn       # The ARN of the IAM role that Lambda will assume to execute the function.
  runtime       = "provided.al2023"                            # The runtime environment for the Lambda function.
  handler       = "main"                                       # The function within your code that Lambda calls to begin execution.
  filename      = "${path.module}/lambda_function_payload.zip" # The path to the deployment package (ZIP file) containing your Lambda code.

  timeout = 180 # The maximum amount of time (in seconds) that the Lambda function can run before being terminated.

  # 'source_code_hash' is used by Terraform to detect changes in your Lambda deployment package.
  # If the hash of the ZIP file changes, Terraform knows it needs to update the Lambda function.
  # `data.archive_file.lambda.output_base64sha256` assumes you have an `archive_file` data source
  # named 'lambda' elsewhere that generates this hash.
  source_code_hash = data.archive_file.lambda.output_base64sha256

  # Defines environment variables for the Lambda function.
  # These variables are accessible within your Lambda code at runtime.
  environment {
    variables = {
      REGION = module.global_config.aws_region # Passes the AWS region as an environment variable to the Lambda.
    }
  }

  # Tags for better resource management
  tags = {
    Name        = module.global_config.project_name
    Environment = module.global_config.environment
  }
}

# This resource creates an AWS IAM role.
# This specific role is intended for the Lambda function to assume during its execution,
# granting it the necessary permissions to interact with other AWS services.
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role" # A unique name for the IAM role.

  # The 'assume_role_policy' defines which entities are allowed to assume this role.
  # `data.aws_iam_policy_document.lambda_execution_policy.json` (defined elsewhere)
  # should specify that the Lambda service (`lambda.amazonaws.com`) is allowed to assume this role.
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_policy.json # Trust policy
}

# This resource attaches a managed IAM policy to an IAM role.
# It grants the Lambda function basic execution permissions, allowing it to
# write logs to Amazon CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name                            # The name of the IAM role to attach the policy to.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # The ARN of the AWS managed policy for basic Lambda execution.
}

# This resource attaches a custom IAM policy to the Lambda execution role.
# This custom policy will grant the Lambda function specific permissions
# required to interact with other services (e.g., DynamoDB, S3) that your
# Lambda function needs to access.
resource "aws_iam_role_policy_attachment" "lambda_access_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name # The name of the IAM role to attach the policy to.
  policy_arn = aws_iam_policy.lambda_access_policy.arn # The ARN of the custom IAM policy created by `aws_iam_policy.lambda_access_policy`.
}

# This resource creates a custom IAM policy.
# This policy will contain specific permissions required by your Lambda function
# beyond basic execution (e.g., read/write access to DynamoDB tables, S3 buckets).
resource "aws_iam_policy" "lambda_access_policy" {
  name = "lambda_dynamodb_policy" # A unique name for the custom IAM policy.

  # The 'policy' attribute holds the JSON policy document.
  # `data.aws_iam_policy_document.allow_lambda_access_policy_doc.json` (defined elsewhere)
  # will contain the actual permissions (e.g., DynamoDB read/write).
  policy = data.aws_iam_policy_document.allow_lambda_access_policy_doc.json
}

# This resource grants invocation permission to the Lambda function.
# It specifically allows Amazon API Gateway to invoke this Lambda function.
# This is crucial for integrating API Gateway with Lambda as a backend.
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"                      # A unique identifier for the permission statement.
  action        = "lambda:InvokeFunction"                             # The action being allowed: invoking the Lambda function.
  function_name = aws_lambda_function.movies_api_lambda.function_name # The name of the Lambda function to grant permission to.
  principal     = "apigateway.amazonaws.com"                          # The service principal that is allowed to invoke the Lambda.

  # The 'source_arn' specifies the ARN of the API Gateway that is allowed to invoke the function.
  # "${aws_api_gateway_rest_api.movies_api_gateway.execution_arn}/*" restricts invocation
  # to the specific API Gateway created, allowing all resources and methods (`/*`) within it.
  source_arn = "${aws_api_gateway_rest_api.movies_api_gateway.execution_arn}/*"
}

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

# This resource creates the main Amazon API Gateway REST API.
resource "aws_api_gateway_rest_api" "movies_api_gateway" {
  name = "movies_api_gateway" # A unique name for the API Gateway.

  # Defines the endpoint configuration for the API.
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # Specifies the content types that the API Gateway will treat as binary.
  # This is crucial for handling file uploads (e.g., images, videos).
  binary_media_types = ["multipart/form-data"]

  # Tags for better resource management
  tags = {
    Name        = module.global_config.project_name
    Environment = module.global_config.environment
  }
}

# This resource defines a specific path or segment within the API Gateway.
# Here, it creates a base path '/api' under the root of the API.
resource "aws_api_gateway_resource" "movies_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.movies_api_gateway.id               # Associates this resource with the main API Gateway.
  parent_id   = aws_api_gateway_rest_api.movies_api_gateway.root_resource_id # Sets the parent to the root of the API Gateway.
  path_part   = "api"                                                        # Defines the path segment as 'api'. "/api"
}

# This resource creates a proxy resource, often denoted by '{proxy+}'.
# A proxy resource with '{proxy+}' captures all requests that match the
# parent path and any sub-paths, including the root of the parent.
resource "aws_api_gateway_resource" "movies_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.movies_api_gateway.id  # Associates this resource with the main API Gateway.
  parent_id   = aws_api_gateway_resource.movies_api_resource.id # Sets the parent to the '/api' resource.
  path_part   = "{proxy+}"                                      # Defines the path segment as a proxy. The path will be: /api/{proxy+}
}

# This resource defines an HTTP method for a specific API Gateway resource.
# Here, it defines the 'ANY' (GET, POST, PUT, DELETE, PATCH, etc.) method for the proxy resource.
resource "aws_api_gateway_method" "movies_any_method" {
  rest_api_id   = aws_api_gateway_rest_api.movies_api_gateway.id    # Associates with the main API Gateway.
  resource_id   = aws_api_gateway_resource.movies_proxy_resource.id # Associates with the '{proxy+}' resource.
  http_method   = "ANY"                                             # Allows all HTTP methods (GET, POST, PUT, DELETE, etc.).
  authorization = "NONE"                                            # Specifies that no authorization is required for this method.

  # Defines request parameters that API Gateway expects to receive.
  # "method.request.path.proxy" = true indicates that the 'proxy' path parameter
  # (from '{proxy+}') is required and will be passed to the integration.
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# This resource defines how API Gateway integrates with a backend service.
# Here, it integrates the 'ANY' method of the proxy resource with an AWS Lambda function.
resource "aws_api_gateway_integration" "movies_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.movies_api_gateway.id       # Associates with the main API Gateway.
  resource_id = aws_api_gateway_resource.movies_proxy_resource.id    # Associates with the '{proxy+}' resource.
  http_method = aws_api_gateway_method.movies_any_method.http_method # Uses the 'ANY' HTTP method defined previously.

  # For AWS_PROXY, this is often POST.
  integration_http_method = "POST" # The HTTP method used to call the backend (Lambda).

  # This means API Gateway passes the raw request directly to Lambda
  # and expects a specific JSON response format back from Lambda.
  # This simplifies configuration as API Gateway doesn't need
  # extensive mapping templates.
  type = "AWS_PROXY" # Specifies the integration type as 'AWS_PROXY'.

  uri = aws_lambda_function.movies_api_lambda.invoke_arn # The ARN of the Lambda function to invoke.
}

# This resource creates a deployment of the API Gateway.
# A deployment makes the configured API Gateway resources, methods, and integrations
# available to be invoked. Without a deployment, changes to the API are not live.
resource "aws_api_gateway_deployment" "movies_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.movies_api_gateway.id # Associates with the main API Gateway.

  # The 'triggers' block is used to force a new deployment whenever certain
  # dependent resources change. This ensures that any updates to the API's
  # structure (resources, methods, integrations, binary media types)
  # automatically trigger a new deployment, making the changes live.
  # sha1(jsonencode([...])) creates a hash of the IDs of the dependent resources.
  # If any of these IDs change, the hash changes, forcing a redeployment.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.movies_api_resource.id,               # Changes to the '/api' resource.
      aws_api_gateway_resource.movies_proxy_resource.id,             # Changes to the '{proxy+}' resource.
      aws_api_gateway_method.movies_any_method.id,                   # Changes to the 'ANY' method.
      aws_api_gateway_integration.movies_lambda_integration.id,      # Changes to the Lambda integration.
      aws_api_gateway_rest_api.movies_api_gateway.binary_media_types # Changes to binary media types.
    ]))
  }

  # The 'lifecycle' block defines custom behaviors for resource creation, update, and deletion.
  lifecycle {
    create_before_destroy = true # Creates a new deployment before destroying the old one to minimize downtime.
  }
}

# This resource creates a stage for the API Gateway deployment.
# A stage is a logical snapshot of your API, identified by a name (e.g., 'dev', 'prod').
resource "aws_api_gateway_stage" "movies_api_dev_stage" {
  deployment_id = aws_api_gateway_deployment.movies_api_deployment.id # Links to the specific API Gateway deployment.
  rest_api_id   = aws_api_gateway_rest_api.movies_api_gateway.id      # Associates with the main API Gateway.
  stage_name    = "dev"                                               # Defines the name of the stage, e.g., 'dev' for development.
}

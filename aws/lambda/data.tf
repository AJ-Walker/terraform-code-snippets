# This data source constructs the **assume role policy** for the Lambda execution role.
# It defines which service is allowed to assume this IAM role.
data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    sid    = "1"     # (Optional) An identifier for the statement
    effect = "Allow" # Explicitly allows the specified actions.

    principals {
      type        = "Service"                # Specifies that a service principal is allowed to assume the role.
      identifiers = ["lambda.amazonaws.com"] # Grants permission for the AWS Lambda service to assume this role.
    }

    actions = ["sts:AssumeRole"] # The specific action allowed: assuming an IAM role.
  }
}

# This data source defines a custom IAM policy document that grants the Lambda function
# necessary permissions to interact with other AWS services like DynamoDB, Amazon Bedrock, and S3.
data "aws_iam_policy_document" "allow_lambda_access_policy_doc" {
  statement {
    sid    = "1"     # (Optional) An identifier for the statement
    effect = "Allow" # Allows the specified actions.

    # Grants various DynamoDB permissions: read (Scan, Query, GetItem) and write (UpdateItem, DeleteItem, PutItem).
    actions = ["dynamodb:Scan", "dynamodb:Query", "dynamodb:UpdateItem", "dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:PutItem"]
    # Applies these permissions to the specific DynamoDB table created for movies.
    resources = [aws_dynamodb_table.movies_db.arn]
  }
  statement {
    sid    = "2"     # (Optional) An identifier for the statement
    effect = "Allow" # Allows the specified actions.

    # Grants permission to invoke Bedrock models.
    actions = ["bedrock:InvokeModel"]

    # Specifies the ARN of the particular Amazon Bedrock foundation model (Claude 3 Sonnet)
    # that the Lambda function is allowed to invoke.
    resources = ["arn:aws:bedrock:ap-south-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"]
  }
  statement {
    sid    = "3"     # (Optional) An identifier for the statement
    effect = "Allow" # Allows the specified actions.

    # Grants permissions to put (upload) and delete objects in S3.
    actions = ["s3:PutObject", "s3:DeleteObject"]

    # Applies these permissions to objects within the S3 bucket's image prefix.
    resources = ["${aws_s3_bucket.movies_rest_api_bucket.arn}/${var.s3_images_prefix}/*"]
  }
}

# This data source is used to create a ZIP archive from a local file,
# which is then used as the deployment package for the AWS Lambda function.
data "archive_file" "lambda" {
  type        = "zip"                                     # Specifies the output archive format as ZIP.
  source_file = "${path.module}/../lambda-code/bootstrap" # The local file to be archived (e.g., your Lambda executable/script).
  output_path = "lambda_function_payload.zip"             # The name and path for the generated ZIP file.
}

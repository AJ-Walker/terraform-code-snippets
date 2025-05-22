data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    sid    = "1"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "allow_lambda_access_policy_doc" {
  statement {
    sid    = "1"
    effect = "Allow"

    actions   = ["dynamodb:Scan", "dynamodb:Query", "dynamodb:UpdateItem", "dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:PutItem"]
    resources = [aws_dynamodb_table.movies_db.arn]
  }
  statement {
    sid    = "2"
    effect = "Allow"

    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:ap-south-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"]
  }
  statement {
    sid    = "3"
    effect = "Allow"

    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.movies_rest_api_bucket.arn}/${var.s3_images_prefix}/*"]
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../lambda-code/bootstrap"
  output_path = "lambda_function_payload.zip"
}
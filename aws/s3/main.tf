module "global_config" {
  source = "../../modules/global_config" # Relative path to your global module

  # You can pass values here if you want to override the default in the global module
  # aws_region = "ap-south-1"
}

provider "aws" {
  region = module.global_config.aws_region
}

locals {
  files      = fileset("${path.module}/${var.local_images_folder}", "*")
}

resource "aws_s3_bucket" "movies_rest_api_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "Movies REST API"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "movies_rest_api_images" {
  for_each     = local.files
  bucket       = aws_s3_bucket.movies_rest_api_bucket.id
  key          = "${var.s3_images_prefix}/${each.value}"
  source       = "${path.module}/${var.local_images_folder}/${each.value}"
  etag         = filemd5("${path.module}/${var.local_images_folder}/${each.value}")
  content_type = "application/octet-stream"
}

resource "aws_s3_bucket_public_access_block" "movies_rest_api_bucket_public_access" {
  bucket = aws_s3_bucket.movies_rest_api_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

resource "aws_s3_bucket_policy" "allow_get_images_policy" {
  bucket = aws_s3_bucket.movies_rest_api_bucket.id
  policy = data.aws_iam_policy_document.allow_get_s3_images_policy.json
}
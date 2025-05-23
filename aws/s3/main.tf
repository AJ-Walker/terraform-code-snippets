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

# Defines a block for local values, which are named expressions that can be used throughout a Terraform configuration.
locals {
  # 'fileset' function generates a set of filenames from a given directory that match a pattern.
  # Here, it lists all files ("*") within the local directory specified by `var.local_images_folder`.
  files = fileset("${path.module}/${var.local_images_folder}", "*")
}

# Creates an Amazon S3 bucket, which is an object storage service for storing and retrieving any amount of data.
resource "aws_s3_bucket" "movies_rest_api_bucket" {
  bucket = var.bucket_name # Name of the S3 bucket using a variable.

  # Tags for better resource management
  tags = {
    Name        = module.global_config.project_name
    Environment = module.global_config.environment
  }
}

# Uploads files from a local directory to the S3 bucket.
resource "aws_s3_object" "movies_rest_api_images" {
  # The 'for_each' meta-argument creates one S3 object for each file found in `local.files`.
  for_each     = local.files
  bucket       = aws_s3_bucket.movies_rest_api_bucket.id                            # Specifies the target S3 bucket by its ID.
  key          = "${var.s3_images_prefix}/${each.value}"                            # Sets the object key (path in S3). It includes a prefix and the filename.
  source       = "${path.module}/${var.local_images_folder}/${each.value}"          # Path to the local file being uploaded.
  etag         = filemd5("${path.module}/${var.local_images_folder}/${each.value}") # A unique identifier for the object, used for integrity checks and to trigger updates.
  content_type = "application/octet-stream"                                         # Sets the MIME type for the uploaded objects, generally for generic binary data.
}

# Manages the S3 bucket's public access block settings.
# This resource explicitly disables all public access blocks for the bucket,
# which is necessary if you intend to make objects or the bucket content publicly accessible (e.g., for website hosting).
resource "aws_s3_bucket_public_access_block" "movies_rest_api_bucket_public_access" {
  bucket = aws_s3_bucket.movies_rest_api_bucket.id # Refers to the S3 bucket created earlier.

  # Setting all these to 'false' means public access is *not* blocked.
  # Use with caution, as it allows for public exposure of bucket content.
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

# Attaches a bucket policy to the S3 bucket, defining access permissions.
resource "aws_s3_bucket_policy" "allow_get_images_policy" {
  bucket = aws_s3_bucket.movies_rest_api_bucket.id                      # The S3 bucket to which the policy will be attached.
  policy = data.aws_iam_policy_document.allow_get_s3_images_policy.json # The JSON policy document to apply.

  # 'depends_on' ensures that the public access block settings are applied
  # before attempting to attach a policy that relies on public access.
  depends_on = [aws_s3_bucket_public_access_block.movies_rest_api_bucket_public_access]
}

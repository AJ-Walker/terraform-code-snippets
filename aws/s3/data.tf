# This data source allows you to construct an IAM policy document in Terraform.
# It doesn't create the policy itself, but rather generates the JSON policy string
# that can then be used by other resources (like `aws_s3_bucket_policy`).
data "aws_iam_policy_document" "allow_get_s3_images_policy" {
  # A 'statement' block defines a single permission statement within the policy.
  statement {
    sid = "1" # (Optional) An identifier for the statement

    # Defines the actions that are allowed or denied.
    # "s3:GetObject" grants permission to retrieve (read) objects from S3.
    actions = ["s3:GetObject"]

    # Specifies the resources to which the actions apply.
    # "arn:aws:s3:::${var.bucket_name}/${var.s3_images_prefix}/*" means
    # the policy applies to all objects (`/*`) within the S3 bucket specified by
    # `var.bucket_name`, under the path prefixed by `var.s3_images_prefix`.
    resources = ["arn:aws:s3:::${var.bucket_name}/${var.s3_images_prefix}/*"]

    # Defines the principal(s) (users, roles, services, or accounts) to whom
    # this permission applies.
    principals {
      type        = "AWS" # Indicates that the principal type is an AWS principal.
      identifiers = ["*"] # "*" means "any principal" or "public access".
    }
  }
}

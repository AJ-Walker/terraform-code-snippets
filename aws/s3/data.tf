data "aws_iam_policy_document" "allow_get_s3_images_policy" {
  statement {
    sid = "1"

    actions = ["s3:GetObject"]

    resources = ["arn:aws:s3:::${var.bucket_name}/${var.s3_images_prefix}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
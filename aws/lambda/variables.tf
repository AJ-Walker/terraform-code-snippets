# Defines the prefix (folder path) within the S3 bucket where images will be stored.
variable "s3_images_prefix" {
  description = "AWS s3 images folder for the image"
  type        = string
  default     = "images"
}
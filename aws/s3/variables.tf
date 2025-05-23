# Defines the name for the Amazon S3 bucket.
variable "bucket_name" {
  description = "AWS s3 bucket name"
  type        = string
  default     = "movies-api-data"
}

# Defines the prefix (folder path) within the S3 bucket where images will be stored.
variable "s3_images_prefix" {
  description = "AWS s3 images folder for the image"
  type        = string
  default     = "images"
}

# Defines the name of the local directory containing the images to be uploaded to S3.
variable "local_images_folder" {
  description = "Local folder name of the images"
  type        = string
  default     = "images"
}
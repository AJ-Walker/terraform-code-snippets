# Global Variables
# This file contains all global variables used across the Terraform modules

# Define the AWS region to deploy the infrastructure in
variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "ap-south-1" # Mumbai region
}

# Define the current environment (e.g., Dev, Staging, Prod)
variable "environment" {
  description = "Current environment of the deployment (e.g., Dev, Staging, Prod)"
  type        = string
  default     = "Dev"
}

# Define the name of the project for resource naming and tagging
variable "project_name" {
  description = "The name of the project used for resource identification and tagging"
  type        = string
  default     = "Movies REST API"
}

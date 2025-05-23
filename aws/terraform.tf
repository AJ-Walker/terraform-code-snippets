# This block defines the minimum Terraform version required and configures
# the required providers for the project.
terraform {
  # 'required_providers' specifies the providers that this Terraform configuration
  # depends on and their versions.
  required_providers {
    aws = {
      source  = "hashicorp/aws" # The source address for the AWS provider.
      version = "~> 5.0"        # Specifies the acceptable version range for the AWS provider.
    }
  }
  # 'required_version' specifies the minimum Terraform CLI version required to run this configuration.
  # This helps ensure compatibility and prevent issues with breaking changes in newer Terraform versions.
  required_version = "~> 1.11.0" # "~> 1.11.0" means any version greater than or equal to 1.11.0
}

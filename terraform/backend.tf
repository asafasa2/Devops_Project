# Terraform state management configuration
# For local development, we use local state
# In production, this would be configured for remote state (S3, etc.)

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
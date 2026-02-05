# IMPORTANT: Update 'bucket' to match the one created by infra-bootstrap workflow
# Format: <your-suffix>-terraform-state
terraform {
  backend "s3" {
    bucket         = "pappukrs611-2026-terraform-state" # <--- MUST UPDATE THIS MANUALLY
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "demo-app-terraform-locks"
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "demo-app"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "node-ec2-key"
}

variable "state_bucket_suffix" {
  description = "Unique suffix for S3 bucket (must be globally unique)"
  type        = string
  default     = "tf-state-2026"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "loan-optimization-execution-bucket"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "admin_role_name" {
  description = "Admin role name"
  type        = string
}

variable "auth_role_name" {
  description = "Authenticated users role name"
  type        = string
}

variable "unauth_role_name" {
  description = "Unauthenticated users role name"
  type        = string
}
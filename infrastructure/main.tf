resource "aws_s3_bucket" "loan_optimization_execution" {
  bucket = var.bucket_name

  force_destroy = true

  tags = {
    Environment = var.environment
    Purpose     = "Main execution bucket for loan optimization team"
  }
}

# Enable AES256 encryption at rest for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
  bucket = aws_s3_bucket.loan_optimization_execution.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the bucket. Only allow access via IAM roles and policies.
# This is done by default but we explicitly define it here for clarity.
resource "aws_s3_bucket_public_access_block" "s3_bucket_disable_public_access" {
  bucket = aws_s3_bucket.loan_optimization_execution.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# The CORS configuration, written in JSON, defines a way for client web applications that
# are loaded in one domain to interact with resources in a different domain.
resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.loan_optimization_execution.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = [
      "http://localhost:3000",
      "http://localhost:5173",
      "https://main.d2k5uxsf6lu8a3.amplifyapp.com"
    ]
    expose_headers  = ["ETag", "x-amz-request-id", "x-amz-id-2"]
    max_age_seconds = 3000
  }
}

# ----------------- IAM Policies ------------------------------
# This policy allows read and write permissions to authenticated users
resource "aws_iam_policy" "s3_auth" {
  name        = "${var.bucket_name}-auth-s3"
  description = "Authenticated user access to public/* and admin/* for ${var.bucket_name}"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "${aws_s3_bucket.loan_optimization_execution.arn}/public/*",
          "${aws_s3_bucket.loan_optimization_execution.arn}/admin/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.loan_optimization_execution.arn
        Condition = {
          StringLike = { "s3:prefix" = ["public/*", "public/", "admin/*", "admin/"] }
        }
      }
    ]
  })
}

# This policy allows read and write permissions to admins
resource "aws_iam_policy" "s3_admin" {
  name        = "${var.bucket_name}-admin-s3"
  description = "Admin group access to admin/* for ${var.bucket_name}"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.loan_optimization_execution.arn}/admin/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.loan_optimization_execution.arn
        Condition = {
          StringLike = { "s3:prefix" = ["admin/*", "admin/"] }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "auth_attach" {
  role       = data.aws_iam_role.auth.name
  policy_arn = aws_iam_policy.s3_auth.arn
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = data.aws_iam_role.admin.name
  policy_arn = aws_iam_policy.s3_admin.arn
}

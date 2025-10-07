data "aws_iam_role" "auth"  {
    name = var.auth_role_name
}

data "aws_iam_role" "admin"  {
    name = var.admin_role_name
}

data "aws_caller_identity" "current" {}

# ----------------------------------------------------------------------------
# IAM group: Developers-${var.suffix} -- gets EC2 full access
# ----------------------------------------------------------------------------

resource "aws_iam_group" "developers" {
  name = "Developers-${var.suffix}"
}

resource "aws_iam_group_policy_attachment" "developers_ec2" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# ----------------------------------------------------------------------------
# Developer user: ${var.suffix}-dev (member of Developers group, has console password)
# ----------------------------------------------------------------------------

resource "aws_iam_user" "dev" {
  name = "${var.suffix}-dev"

  tags = {
    Owner = var.display_name
    Role  = "Developer"
  }
}

resource "aws_iam_user_group_membership" "dev" {
  user   = aws_iam_user.dev.name
  groups = [aws_iam_group.developers.name]
}

resource "aws_iam_user_login_profile" "dev" {
  user                    = aws_iam_user.dev.name
  password_reset_required = false
  password_length         = 16
}

# ----------------------------------------------------------------------------
# Read-only user: ${var.suffix}-readonly (direct policy attachment, no console login)
# ----------------------------------------------------------------------------

resource "aws_iam_user" "readonly" {
  name = "${var.suffix}-readonly"

  tags = {
    Owner = var.display_name
    Role  = "ReadOnly"
  }
}

resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

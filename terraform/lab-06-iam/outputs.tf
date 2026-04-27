output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS account ID (use this when logging in as IAM user)"
}

output "console_login_url" {
  value       = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
  description = "Use this URL to sign in as mukesh-dev"
}

output "dev_username" {
  value       = aws_iam_user.dev.name
  description = "Username for the Developer user"
}

output "dev_password" {
  value       = aws_iam_user_login_profile.dev.password
  sensitive   = true
  description = "Console password for mukesh-dev (run 'terraform output dev_password' to reveal)"
}

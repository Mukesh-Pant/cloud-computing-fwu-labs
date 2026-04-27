output "instance_id" {
  value       = aws_instance.mukesh.id
  description = "EC2 instance ID"
}

output "public_ip" {
  value       = aws_instance.mukesh.public_ip
  description = "Public IPv4 address of the instance"
}

output "public_url" {
  value       = "http://${aws_instance.mukesh.public_ip}"
  description = "Open this in a browser to see the welcome page"
}

output "ami_id" {
  value       = data.aws_ami.al2023.id
  description = "Amazon Linux 2023 AMI used"
}

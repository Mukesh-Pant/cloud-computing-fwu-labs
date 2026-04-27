output "topic_arn" {
  value       = aws_sns_topic.main.arn
  description = "SNS topic ARN"
}

output "topic_name" {
  value       = aws_sns_topic.main.name
  description = "SNS topic name"
}

output "queue_url" {
  value       = aws_sqs_queue.main.url
  description = "SQS queue URL"
}

output "queue_name" {
  value       = aws_sqs_queue.main.name
  description = "SQS queue name"
}

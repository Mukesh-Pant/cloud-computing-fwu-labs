# ============================================================================
# SNS topic
# ============================================================================

resource "aws_sns_topic" "main" {
  name = "sns-${var.suffix}-notifications"

  tags = {
    Name = "sns-${var.suffix}-notifications"
  }
}

# ============================================================================
# SQS queue
# ============================================================================

resource "aws_sqs_queue" "main" {
  name                       = "sqs-${var.suffix}-orders"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600 # 4 days

  tags = {
    Name = "sqs-${var.suffix}-orders"
  }
}

# Allow SNS to deliver messages to SQS
resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSNSPublish"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.main.arn
          }
        }
      }
    ]
  })
}

# ============================================================================
# Subscriptions: SQS queue + email
# ============================================================================

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = var.subscriber_email
}

output "lambda_name" {
  value       = aws_lambda_function.logger.function_name
  description = "Name of the Lambda function"
}

output "dynamodb_table" {
  value       = aws_dynamodb_table.visitors.name
  description = "DynamoDB table name"
}

output "fargate_cluster" {
  value       = aws_ecs_cluster.main.name
  description = "Fargate cluster name"
}

output "task_definition" {
  value       = aws_ecs_task_definition.nginx.family
  description = "Fargate task definition family name"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.nginx.arn
  description = "Fargate task definition ARN"
}

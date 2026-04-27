variable "lab_name" {
  type    = string
  default = "lab-08-sns-sqs"
}

variable "subscriber_email" {
  type        = string
  description = "Email address that will receive SNS notifications. AWS sends a confirmation link to this address."
}

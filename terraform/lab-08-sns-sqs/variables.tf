variable "lab_name" {
  type    = string
  default = "lab-08-sns-sqs"
}

variable "suffix" {
  type    = string
  default = "mukesh"
}

variable "display_name" {
  type    = string
  default = "Mukesh"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "subscriber_email" {
  type        = string
  description = "Email address that will receive SNS notifications. AWS sends a confirmation link to this address."
}

variable "lab_name" {
  type    = string
  default = "lab-01-vpc"
}

variable "suffix" {
  type        = string
  description = "Lowercase identifier used in resource names (e.g. 'mukesh')"
  default     = "mukesh"
}

variable "display_name" {
  type        = string
  description = "Short display name used in tags (e.g. 'Mukesh')"
  default     = "Mukesh"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidrs" {
  description = "vpc cidrs"
  type        = string
}

variable name_prefix {
  type        = string
  description = "Prefix for resource names usually in the format project-env"
}

variable "ha" {
  type        = number
  default     = 3
  description = "High Availabilty Redundancy"
}

variable "vpc_cidrs" {
  description = "vpc cidrs"
  type        = string
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names usually in the format project-env"
}

variable "availability_zones" {
  type        = number
  description = "Amount of availability zones to use for the VPC"

}
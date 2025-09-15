variable "ha" {
  type        = number
  default     = "3"
  description = "High Availabilty Redundancy"
}

variable "vpc_cidrs" {
  description = "vpc cidrs"
  type        = string
}

variable "common_tags" {
  default = {
    owner           = "terraform-eks"
    managedBy       = "terraform"
    app_name        = "feature-flags"
  }
}

variable "region" {
  type        = string
  default     = "ap-south-1"
}

variable "cluster_version" {
    type      = string
}

variable "node_type" {
  type        = string
}

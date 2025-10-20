variable "aws_region" {
  type = string
}
variable "name_prefix" {
  type = string
}
variable "terraform_backend" {
  type = string
}
variable "force_destroy" {
  type = bool
}
variable "versioning" {
  type = bool
}
variable "block_public_access" {
  type = bool
}
variable "force_ssl_policy" {
  type = bool
}

variable "server_side_encryption" {
  type = bool
}         
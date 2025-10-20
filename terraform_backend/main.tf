module "terraform_backend" {
  source = "../modules/s3"

  name_prefix            = var.name_prefix
  bucket_name            = var.terraform_backend
  force_destroy          = var.force_destroy
  versioning             = var.versioning
  block_public_access    = var.block_public_access
  force_ssl_policy       = var.force_ssl_policy
  server_side_encryption = var.server_side_encryption
}
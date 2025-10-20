
output "record_fqdns" {
  value = [for k, v in var.sub_domains : "${k}.${var.domain_name}"]
}
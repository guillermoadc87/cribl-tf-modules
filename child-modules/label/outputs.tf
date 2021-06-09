output "name" {
  value       = local.name
  description = "Disambiguated ID"
}

output "tags" {
  value       = local.tags
  description = "Normalized Tag map"
}

output "domain_prefix" {
  value       = local.domain_prefix
  description = "Domain prefix (always lowercase)"
}

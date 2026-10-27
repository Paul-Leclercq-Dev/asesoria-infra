output "zone_id" {
  value = cloudflare_zone.this.id
}

output "name_servers" {
  description = "Serveurs DNS Cloudflare à déclarer chez le registrar (OVH)."
  value       = cloudflare_zone.this.name_servers
}

output "status" {
  description = "`pending` tant que la délégation n'est pas vue par Cloudflare, puis `active`."
  value       = cloudflare_zone.this.status
}

output "server_ipv4" {
  value = try(module.server[0].ipv4, null)
}

output "ssh" {
  value = try(module.server[0].ssh, null)
}

output "kube_tunnel" {
  description = "Tunnel vers l'API Kubernetes (6443 n'est pas exposé)."
  value       = try("ssh -N -L 6443:127.0.0.1:6443 deploy@${module.server[0].ipv4}", null)
}

output "name_servers" {
  description = "À déclarer chez OVH (Noms de domaine → Serveurs DNS → Modifier)."
  value       = { for k, z in module.zone : k => z.name_servers }
}

output "email_routing_status" {
  description = "« ready » = Cloudflare reçoit le courrier de tramelya.com ; « misconfigured » = MX étrangers encore présents."
  value       = cloudflare_email_routing_dns.mail.status
}

output "contact_forward_verified" {
  description = "Date de vérification de la boîte de destination ; null = cliquer le lien reçu par e-mail, puis `terraform apply -refresh-only`."
  value       = cloudflare_email_routing_address.contact.verified
}

output "zone_status" {
  value = { for k, z in module.zone : k => z.status }
}

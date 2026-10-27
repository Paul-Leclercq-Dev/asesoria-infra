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

output "zone_status" {
  value = { for k, z in module.zone : k => z.status }
}

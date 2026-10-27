output "ipv4" {
  description = "Adresse IPv4 publique de l'instance."
  value       = openstack_compute_instance_v2.this.access_ip_v4
}

output "id" {
  value = openstack_compute_instance_v2.this.id
}

output "ssh" {
  description = "Commande SSH d'administration."
  value       = "ssh ${var.admin_username}@${openstack_compute_instance_v2.this.access_ip_v4}"
}

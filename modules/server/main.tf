# Groupe de sécurité : tout est fermé en entrée sauf
# - 22/tcp depuis les IP d'administration ;
# - 443/tcp depuis Cloudflare (le DNS est proxifié, l'origine n'est jamais exposée en direct).
# Pas de 80 (HTTPS forcé chez Cloudflare, certificats en DNS-01) ni de 6443 (tunnel SSH).
resource "openstack_networking_secgroup_v2" "this" {
  name                 = "${var.name}-sg"
  description          = "tramelya ${var.name} : SSH admin + HTTPS Cloudflare"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "egress" {
  for_each = toset(["IPv4", "IPv6"])

  security_group_id = openstack_networking_secgroup_v2.this.id
  direction         = "egress"
  ethertype         = each.value
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  for_each = toset(var.admin_cidrs)

  security_group_id = openstack_networking_secgroup_v2.this.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = each.value
  description       = "SSH admin"
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  for_each = toset(var.https_cidrs)

  security_group_id = openstack_networking_secgroup_v2.this.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = each.value
  description       = "HTTPS Cloudflare"
}

resource "openstack_compute_instance_v2" "this" {
  name                = var.name
  flavor_name         = var.flavor_name
  image_name          = var.image_name
  security_groups     = [openstack_networking_secgroup_v2.this.name]
  stop_before_destroy = true

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    hostname        = var.name
    admin_username  = var.admin_username
    ssh_public_keys = jsonencode(var.ssh_public_keys)
    k3s_channel     = var.k3s_channel
  })

  network {
    name = var.network_name
  }

  metadata = {
    project = "tramelya"
    managed = "terraform"
  }
}

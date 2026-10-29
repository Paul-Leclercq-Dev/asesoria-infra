# Environnement de démonstration : un nœud k3s tout-en-un + DNS des deux domaines.
# Hors périodes de démo : `terraform apply -var server_enabled=false` supprime le
# serveur (seul poste payant) et son entrée DNS, mais garde les zones Cloudflare :
# leurs serveurs DNS ne changent pas, aucune re-délégation chez OVH.

data "cloudflare_ip_ranges" "this" {}

module "server" {
  source = "../../modules/server"
  count  = var.server_enabled ? 1 : 0

  name            = "tramelya-demo-1"
  flavor_name     = var.flavor_name
  ssh_public_keys = var.ssh_public_keys
  admin_cidrs     = var.admin_cidrs
  https_cidrs     = data.cloudflare_ip_ranges.this.ipv4_cidrs
  k3s_channel     = var.k3s_channel
}

locals {
  zones = {
    "tramelya.es" = var.server_enabled ? {
      app = {
        name    = "app"
        type    = "A"
        content = module.server[0].ipv4
        proxied = true
        comment = "Application (demo)"
      }
    } : {}
    # .com : marque + e-mail (Google Workspace, à venir) ; aucune entrée applicative.
    "tramelya.com" = {}
  }

  # Domaines qui ENVOIENT des e-mails : pas de SPF « -all » ni de DMARC « reject »
  # (ils bloqueraient nos propres e-mails). Leurs entrées mail (MX, SPF, DKIM, DMARC)
  # seront ajoutées ici, dans `records`, lors de la mise en place de Google Workspace.
  mail_domains = ["tramelya.com"]
}

module "zone" {
  source   = "../../modules/cloudflare-zone"
  for_each = local.zones

  account_id = var.cloudflare_account_id
  name       = each.key
  ssl_mode   = var.ssl_mode
  records    = each.value
  no_mail    = !contains(local.mail_domains, each.key)
}

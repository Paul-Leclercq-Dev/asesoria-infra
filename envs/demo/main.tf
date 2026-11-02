# Environnement de démonstration : un nœud k3s tout-en-un + DNS des deux domaines.
# Hors périodes de démo : `terraform apply -var server_enabled=false` supprime le
# serveur (seul poste payant) et son entrée DNS, mais garde les zones Cloudflare :
# leurs serveurs DNS ne changent pas, aucune re-délégation chez OVH.

data "cloudflare_ip_ranges" "this" {}

module "server" {
  source = "../../modules/server"
  count  = var.server_enabled ? 1 : 0

  name            = "tramelya-demo-1"
  region          = var.region
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
    # .com : marque + e-mail ENTRANT (Email Routing, voir email.tf) ; aucune entrée applicative.
    "tramelya.com" = {
      # Personne n'envoie encore d'e-mail en @tramelya.com : on rejette les usurpations.
      # Sans effet sur le transfert (le DMARC appliqué est celui de l'expéditeur
      # d'origine). Alignement souple : un futur SMTP d'envoi (sous-domaine de
      # rebond) restera aligné ; passer à p=none le temps de le mettre en place.
      dmarc = {
        name    = "_dmarc"
        type    = "TXT"
        content = "v=DMARC1; p=reject; sp=reject"
        ttl     = 3600
        comment = "Rejet des e-mails usurpant ce domaine (aucun envoi pour l'instant)"
      }
    }
  }

  # Domaines qui REÇOIVENT des e-mails : le module ne publie ni SPF « -all » ni
  # DMARC. Le SPF (et les MX, DKIM) est publié par Cloudflare Email Routing ;
  # un second SPF rendrait les deux invalides. Le DMARC est déclaré ci-dessus.
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

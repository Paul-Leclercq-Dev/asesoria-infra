# E-mail entrant de tramelya.com : Cloudflare Email Routing (gratuit).
# Cloudflare reçoit le courrier sur ses propres MX et le TRANSFÈRE vers une boîte
# existante. Il n'héberge aucune boîte et n'envoie rien au nom du domaine :
# l'envoi « au nom de » viendra avec un SMTP externe, au moment de prospecter.
#
# Prérequis (une fois, à la main) : supprimer dans Cloudflare les MX et le SPF
# recopiés d'OVH sur tramelya.com. Cloudflare refuse d'activer le routage tant
# qu'il existe d'autres MX (erreur 2008). Voir docs/email.fr.md.
# Le catch-all n'est pas géré : par défaut désactivé, une adresse inconnue est refusée.

locals {
  mail_zone = "tramelya.com"
}

# Active le routage. Cloudflare ajoute et VERROUILLE ses entrées (MX route1/2/3,
# SPF `include:_spf.mx.cloudflare.net`, clé DKIM) : elles appartiennent à Email
# Routing, pas à `cloudflare_dns_record`. Le détruire désactive le routage et les retire.
# (`cloudflare_email_routing_settings` n'est pas utilisé : il appelle une route
# d'API dépréciée, `POST /email/routing/enable`.)
resource "cloudflare_email_routing_dns" "mail" {
  zone_id = module.zone[local.mail_zone].zone_id
  name    = local.mail_zone
}

# Boîte de destination, déclarée au niveau du COMPTE Cloudflare (partageable
# entre zones). À sa création, Cloudflare y envoie un e-mail de vérification :
# rien n'est transféré tant que le lien n'a pas été cliqué.
resource "cloudflare_email_routing_address" "contact" {
  account_id = var.cloudflare_account_id
  email      = var.contact_forward_to
}

resource "cloudflare_email_routing_rule" "contact" {
  zone_id = module.zone[local.mail_zone].zone_id
  name    = "contact - transfert vers la boite de l'administrateur"
  enabled = true

  matchers = [{
    type  = "literal"
    field = "to"
    value = "contact@${local.mail_zone}"
  }]

  actions = [{
    type  = "forward"
    value = [cloudflare_email_routing_address.contact.email]
  }]

  depends_on = [cloudflare_email_routing_dns.mail]
}

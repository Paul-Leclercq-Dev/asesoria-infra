resource "cloudflare_zone" "this" {
  account = {
    id = var.account_id
  }
  name = var.name
  type = "full"
}

locals {
  settings = {
    ssl              = var.ssl_mode
    always_use_https = "on"
    min_tls_version  = "1.2"
  }

  anti_spoofing = var.no_mail ? {
    spf = {
      name    = "@"
      type    = "TXT"
      content = "v=spf1 -all"
      proxied = false
      ttl     = 3600
      comment = "Aucun envoi d'e-mail autorise pour ce domaine"
    }
    dmarc = {
      name    = "_dmarc"
      type    = "TXT"
      content = "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s"
      proxied = false
      ttl     = 3600
      comment = "Rejet des e-mails usurpant ce domaine"
    }
  } : {}

  records = merge(local.anti_spoofing, var.records)
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.settings

  zone_id    = cloudflare_zone.this.id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_dns_record" "this" {
  for_each = local.records

  zone_id = cloudflare_zone.this.id
  name    = each.value.name == "@" ? var.name : "${each.value.name}.${var.name}"
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  ttl     = each.value.proxied ? 1 : each.value.ttl
  comment = each.value.comment
}

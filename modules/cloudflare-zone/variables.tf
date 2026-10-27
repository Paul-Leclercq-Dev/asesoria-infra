variable "account_id" {
  description = "Identifiant du compte Cloudflare."
  type        = string
}

variable "name" {
  description = "Nom de domaine de la zone (ex. tramelya.es)."
  type        = string
}

variable "ssl_mode" {
  description = "Mode SSL Cloudflare → origine. `full` tant que l'origine sert un certificat auto-signé (4.1) ; `strict` dès cert-manager (4.2)."
  type        = string
  default     = "full"

  validation {
    condition     = contains(["full", "strict"], var.ssl_mode)
    error_message = "Seuls `full` et `strict` chiffrent la liaison Cloudflare → origine."
  }
}

variable "records" {
  description = "Enregistrements DNS, indexés par une clé stable. `name` = sous-domaine ou @."
  type = map(object({
    name    = string
    type    = string
    content = string
    proxied = optional(bool, false)
    ttl     = optional(number, 1)
    comment = optional(string)
  }))
  default = {}
}

variable "no_mail" {
  description = "Publie SPF `-all` et DMARC `reject` : personne ne peut envoyer d'e-mail au nom du domaine. À remplacer quand un domaine enverra des e-mails."
  type        = bool
  default     = true
}

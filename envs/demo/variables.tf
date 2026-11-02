variable "ovh_project_id" {
  description = "Identifiant du projet OVHcloud Public Cloud."
  type        = string
}

variable "region" {
  description = "Région OVHcloud des instances (UE). SBG7 (Strasbourg) : GRA11 refusait les d2-8 (« No valid host », ADR-001 §11)."
  type        = string
  default     = "SBG7"
}

variable "flavor_name" {
  description = "d2-8 (4 vCore, 8 Go) : 6,5 Go libres après k3s, assez pour Argo CD. d2-4 si le budget l'impose (Flux au lieu d'Argo CD)."
  type        = string
  default     = "d2-8"
}

variable "cloudflare_account_id" {
  description = "Identifiant du compte Cloudflare (tableau de bord → page d'un domaine → « Account ID »)."
  type        = string
}

variable "ssh_public_keys" {
  description = "Clés publiques SSH de l'administrateur."
  type        = list(string)
}

variable "admin_cidrs" {
  description = "IPv4 autorisées en SSH. [\"0.0.0.0/0\"] = depuis partout (portable), protégé par clé SSH + fail2ban ; sinon des /32."
  type        = list(string)
}

variable "k3s_channel" {
  description = "Canal k3s ; figer la mineure (ex. v1.34) une fois la première installation validée."
  type        = string
  default     = "stable"
}

variable "ssl_mode" {
  description = "`full` en 4.1 (certificat auto-signé de Traefik), `strict` en 4.2 (cert-manager)."
  type        = string
  default     = "full"
}

variable "contact_forward_to" {
  description = "Boîte qui reçoit les e-mails de contact@tramelya.com. Donnée personnelle : seulement dans terraform.tfvars (ignoré par Git), jamais dans le dépôt."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.contact_forward_to)) && !endswith(lower(var.contact_forward_to), "@tramelya.com")
    error_message = "Une adresse e-mail complète, hors tramelya.com (transférer contact@ vers le même domaine ferait une boucle)."
  }
}

variable "server_enabled" {
  description = "false = serveur détruit (plus aucun coût de calcul), zones DNS conservées."
  type        = bool
  default     = true
}

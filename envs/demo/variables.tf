variable "ovh_project_id" {
  description = "Identifiant du projet OVHcloud Public Cloud."
  type        = string
}

variable "region" {
  description = "Région OVHcloud des instances (Gravelines : données dans l'UE)."
  type        = string
  default     = "GRA11"
}

variable "flavor_name" {
  description = "d2-8 (4 vCore, 8 Go) par défaut ; d2-4 si le budget l'impose (Flux au lieu d'Argo CD)."
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

variable "server_enabled" {
  description = "false = serveur détruit (plus aucun coût de calcul), zones DNS conservées."
  type        = bool
  default     = true
}

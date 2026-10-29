variable "name" {
  description = "Nom de l'instance (sert aussi de hostname et de nom de nœud k3s)."
  type        = string
}

variable "flavor_name" {
  description = "Gabarit OVHcloud (ex. d2-8 : 4 vCore, 8 Go)."
  type        = string
}

variable "image_name" {
  description = "Image système (nom OVHcloud, résolu par OpenStack)."
  type        = string
  default     = "Ubuntu 24.04"
}

variable "network_name" {
  description = "Réseau public OVHcloud."
  type        = string
  default     = "Ext-Net"
}

variable "admin_username" {
  description = "Utilisateur Linux d'administration (non-root, SSH par clé uniquement)."
  type        = string
  default     = "deploy"
}

variable "ssh_public_keys" {
  description = "Clés publiques SSH autorisées pour l'utilisateur d'administration."
  type        = list(string)

  validation {
    condition     = length(var.ssh_public_keys) > 0 && alltrue([for k in var.ssh_public_keys : can(regex("^(ssh-ed25519|ecdsa-sha2-nistp256|ssh-rsa) ", k))])
    error_message = "Au moins une clé publique SSH valide (ed25519 recommandé)."
  }
}

variable "admin_cidrs" {
  description = "Plages IPv4 autorisées en SSH : des /32 précis, ou [\"0.0.0.0/0\"] pour un poste mobile (accès par clé uniquement, voir ADR-001 §10)."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && alltrue([for c in var.admin_cidrs : can(cidrnetmask(c))])
    error_message = "Au moins un CIDR IPv4 valide (ex. 203.0.113.10/32 ou 0.0.0.0/0)."
  }
}

variable "https_cidrs" {
  description = "Plages IPv4 autorisées en HTTPS (443) : celles de Cloudflare, le proxy est obligatoire."
  type        = list(string)
}

variable "k3s_channel" {
  description = "Canal d'installation k3s (`stable`, ou une mineure figée comme `v1.34`)."
  type        = string
  default     = "stable"
}

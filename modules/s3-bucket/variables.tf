variable "ovh_project_id" {
  description = "Identifiant du projet OVHcloud Public Cloud (service_name)."
  type        = string
}

variable "region" {
  description = "Région du stockage objet, en majuscules pour l'API OVH (GRA, SBG…)."
  type        = string
}

variable "name" {
  description = "Nom du bucket (minuscules, chiffres, tirets ; 3 à 63 caractères)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Nom de bucket S3 invalide."
  }
}

variable "purpose" {
  description = "À quoi sert le bucket (étiquette et description de l'utilisateur)."
  type        = string
}

variable "versioning" {
  description = "Conserver les anciennes versions des objets (utile pour une sauvegarde, inutile pour des données de démo)."
  type        = bool
  default     = false
}

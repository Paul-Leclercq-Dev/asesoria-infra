variable "ovh_project_id" {
  description = "Identifiant du projet OVHcloud Public Cloud (service_name)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.ovh_project_id))
    error_message = "L'identifiant de projet OVH fait 32 caractères hexadécimaux."
  }
}

variable "storage_region" {
  description = "Région du stockage objet (S3) qui porte le state."
  type        = string
  default     = "GRA"
}

variable "state_bucket_name" {
  description = "Nom du bucket du state ; doit être identique à `bucket` dans backend.hcl."
  type        = string
  default     = "tramelya-tfstate"
}

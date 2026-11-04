variable "ovh_project_id" {
  description = "Identifiant du projet OVHcloud Public Cloud (service_name)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.ovh_project_id))
    error_message = "L'identifiant de projet OVH fait 32 caractères hexadécimaux."
  }
}

variable "storage_region" {
  description = "Région du stockage objet. GRA : même région que le state, déjà éprouvée."
  type        = string
  default     = "GRA"
}

variable "documents_bucket_name" {
  description = "Bucket des documents du CRM de démo (S3_BUCKET de l'API)."
  type        = string
  default     = "tramelya-demo-documents"
}

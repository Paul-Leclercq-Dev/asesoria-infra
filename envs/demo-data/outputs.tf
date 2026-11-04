# Valeurs à reporter dans le secret « acrm-s3 » du dépôt asesoria-gitops
# (scripts/acrm-secrets.sh les lit directement ; voir docs/storage.fr.md).

output "s3_endpoint" {
  description = "S3_ENDPOINT et S3_PUBLIC_ENDPOINT de l'API."
  value       = "https://s3.${lower(var.storage_region)}.io.cloud.ovh.net"
}

output "s3_region" {
  description = "S3_REGION de l'API."
  value       = lower(var.storage_region)
}

output "documents_bucket" {
  description = "S3_BUCKET de l'API."
  value       = module.documents.name
}

output "documents_access_key_id" {
  description = "S3_ACCESS_KEY_ID de l'API (utilisateur limité à ce bucket)."
  value       = module.documents.access_key_id
}

output "documents_secret_access_key" {
  description = "S3_SECRET_ACCESS_KEY de l'API."
  value       = module.documents.secret_access_key
  sensitive   = true
}

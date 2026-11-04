# Données de l'environnement de démonstration : ce qui doit SURVIVRE au serveur.
# Racine séparée de envs/demo (state séparé) : `terraform apply -var
# server_enabled=false` ou même `terraform destroy` dans envs/demo ne peuvent
# pas toucher à ces ressources. On n'applique cette racine qu'une fois.
#
# Données fictives uniquement (seed) : pas de versioning ni de prevent_destroy.
# Pour un pilote avec de vraies données : versioning, réplication et sauvegarde
# hors site (phase 5).

module "documents" {
  source = "../../modules/s3-bucket"

  ovh_project_id = var.ovh_project_id
  region         = var.storage_region
  name           = var.documents_bucket_name
  purpose        = "crm-documents-demo"
}

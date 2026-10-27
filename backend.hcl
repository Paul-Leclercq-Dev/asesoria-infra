# Configuration partagée du state distant (OVHcloud Object Storage, compatible S3).
# Aucune donnée secrète ici : les identifiants viennent de AWS_ACCESS_KEY_ID /
# AWS_SECRET_ACCESS_KEY (utilisateur « tf-state » créé par bootstrap/).
# La clé (`key`) est donnée par chaque racine : -backend-config="key=<racine>/terraform.tfstate".
bucket    = "tramelya-tfstate"
region    = "gra"
endpoints = {
  s3 = "https://s3.gra.io.cloud.ovh.net"
}
use_path_style              = true
skip_credentials_validation = true
skip_region_validation      = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
skip_s3_checksum            = true
# Verrou natif S3 (Terraform >= 1.10, écriture conditionnelle).
# Si `init`/`plan` échoue sur le verrou, OVH ne gère pas If-None-Match : passer à false
# (un seul opérateur, risque accepté) et le noter dans docs/adr/001.
use_lockfile = true

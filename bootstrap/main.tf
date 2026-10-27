# Racine « bootstrap » : ce qui doit exister AVANT tout le reste.
# - le bucket du state Terraform (versionné, chiffré, protégé contre la destruction) ;
# - un utilisateur S3 qui n'a accès qu'à ce bucket (state) ;
# - un utilisateur OpenStack aux droits limités (instances, réseau, groupes de sécurité)
#   utilisé par envs/*.
# Premier passage en state local, puis migration du state dans le bucket lui-même
# (renommer backend.tf.disabled en backend.tf, puis `terraform init -migrate-state`).

resource "ovh_cloud_project_storage" "tfstate" {
  service_name = var.ovh_project_id
  region_name  = var.storage_region
  name         = var.state_bucket_name

  versioning = {
    status = "enabled"
  }

  encryption = {
    sse_algorithm = "AES256"
  }

  tags = {
    project = "tramelya"
    purpose = "terraform-state"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "ovh_cloud_project_user" "tf_state" {
  service_name = var.ovh_project_id
  description  = "tramelya: acces au bucket du state Terraform uniquement"
  role_names   = ["objectstore_operator"]
}

resource "ovh_cloud_project_user_s3_credential" "tf_state" {
  service_name = var.ovh_project_id
  user_id      = ovh_cloud_project_user.tf_state.id
}

# Le rôle objectstore_operator donne accès à tous les buckets du projet :
# la policy S3 le restreint au seul bucket du state.
resource "ovh_cloud_project_user_s3_policy" "tf_state" {
  service_name = var.ovh_project_id
  user_id      = ovh_cloud_project_user.tf_state.id
  policy = jsonencode({
    Statement = [{
      Sid    = "TerraformStateOnly"
      Effect = "Allow"
      Action = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:DeleteObject",
      ]
      Resource = [
        "arn:aws:s3:::${var.state_bucket_name}",
        "arn:aws:s3:::${var.state_bucket_name}/*",
      ]
    }]
  })
}

resource "ovh_cloud_project_user" "tf_openstack" {
  service_name = var.ovh_project_id
  description  = "tramelya: Terraform envs (instances, reseau, groupes de securite)"
  role_names = [
    "compute_operator",
    "network_operator",
    "network_security_operator",
  ]
}

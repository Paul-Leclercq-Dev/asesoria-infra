# Un bucket S3 OVHcloud + un utilisateur qui n'a accès qu'à lui.
# Même schéma que le bucket du state (bootstrap/) : le rôle objectstore_operator
# ouvre TOUS les buckets du projet, la policy S3 le restreint à celui-ci.
# Si la clé fuit (ex. depuis un pod), elle ne donne accès qu'à ce bucket.

resource "ovh_cloud_project_storage" "this" {
  service_name = var.ovh_project_id
  region_name  = var.region
  name         = var.name

  # Sans versioning : attribut absent (valeur par défaut d'OVH), plutôt qu'un
  # statut « disabled » que l'API pourrait refuser à la création.
  versioning = var.versioning ? { status = "enabled" } : null

  encryption = {
    sse_algorithm = "AES256"
  }

  tags = {
    project = "tramelya"
    purpose = var.purpose
  }
}

resource "ovh_cloud_project_user" "this" {
  service_name = var.ovh_project_id
  description  = "tramelya: acces au bucket ${var.name} uniquement"
  role_names   = ["objectstore_operator"]
}

resource "ovh_cloud_project_user_s3_credential" "this" {
  service_name = var.ovh_project_id
  user_id      = ovh_cloud_project_user.this.id
}

# Actions limitées à ce que fait l'API (envoi, lecture par URL présignée,
# suppression par le worker). OVH refuse les actions qu'il ne connaît pas
# (ex. s3:GetObjectVersion, vécu en bootstrap) : liste volontairement courte.
resource "ovh_cloud_project_user_s3_policy" "this" {
  service_name = var.ovh_project_id
  user_id      = ovh_cloud_project_user.this.id
  policy = jsonencode({
    Statement = [{
      Sid    = "BucketOnly"
      Effect = "Allow"
      Action = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
      ]
      Resource = [
        "arn:aws:s3:::${ovh_cloud_project_storage.this.name}",
        "arn:aws:s3:::${ovh_cloud_project_storage.this.name}/*",
      ]
    }]
  })
}

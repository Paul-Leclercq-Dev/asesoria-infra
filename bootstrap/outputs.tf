output "ovh_project_id" {
  description = "À exporter en OS_PROJECT_ID / TF_VAR_ovh_project_id pour envs/*."
  value       = var.ovh_project_id
}

output "state_bucket" {
  value = ovh_cloud_project_storage.tfstate.name
}

output "state_access_key_id" {
  description = "AWS_ACCESS_KEY_ID pour le backend S3 (à ranger dans le gestionnaire de mots de passe)."
  value       = ovh_cloud_project_user_s3_credential.tf_state.access_key_id
}

output "state_secret_access_key" {
  description = "AWS_SECRET_ACCESS_KEY pour le backend S3."
  value       = ovh_cloud_project_user_s3_credential.tf_state.secret_access_key
  sensitive   = true
}

output "openstack_username" {
  description = "OS_USERNAME pour envs/*."
  value       = ovh_cloud_project_user.tf_openstack.username
}

output "openstack_password" {
  description = "OS_PASSWORD pour envs/* (renvoyé une seule fois à la création)."
  value       = ovh_cloud_project_user.tf_openstack.password
  sensitive   = true
}

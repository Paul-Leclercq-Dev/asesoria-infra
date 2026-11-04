output "name" {
  value = ovh_cloud_project_storage.this.name
}

output "access_key_id" {
  value = ovh_cloud_project_user_s3_credential.this.access_key_id
}

output "secret_access_key" {
  value     = ovh_cloud_project_user_s3_credential.this.secret_access_key
  sensitive = true
}

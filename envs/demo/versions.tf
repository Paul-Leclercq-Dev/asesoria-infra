terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.4"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
  }

  # Configuration partielle : ../../backend.hcl + key=demo/terraform.tfstate
  backend "s3" {}
}

# Identifiants : OS_USERNAME + OS_PASSWORD (utilisateur créé par bootstrap/).
provider "openstack" {
  auth_url            = "https://auth.cloud.ovh.net/v3"
  region              = var.region
  tenant_id           = var.ovh_project_id
  user_domain_name    = "Default"
  project_domain_name = "Default"
}

# Identifiant : CLOUDFLARE_API_TOKEN (Zone:Edit, Zone Settings:Edit, DNS:Edit sur le compte).
provider "cloudflare" {}

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.23"
    }
  }

  # Configuration partielle : ../../backend.hcl + key=demo-data/terraform.tfstate
  backend "s3" {}
}

# Identifiants : OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
# (jeton NEUF, mêmes droits que celui de bootstrap/ : /cloud/project/<id>/*, voir docs/storage.fr.md).
provider "ovh" {
  endpoint = "ovh-eu"
}

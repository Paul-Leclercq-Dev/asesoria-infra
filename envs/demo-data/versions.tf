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
# (le même jeton d'API limité à /cloud/project/<id>/* que bootstrap/).
provider "ovh" {
  endpoint = "ovh-eu"
}

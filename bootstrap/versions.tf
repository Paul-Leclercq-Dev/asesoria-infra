terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.23"
    }
  }
}

# Identifiants : OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
# (jeton d'API limité à /cloud/project/<id>/*, voir docs/bootstrap.fr.md).
provider "ovh" {
  endpoint = "ovh-eu"
}

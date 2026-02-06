# ===============================================================================
# FILE: main.tf
# ===============================================================================
# Defines required Terraform providers and configures Google Cloud access.
#
# This module:
#   - Pins Google and Google Beta providers to compatible major versions
#   - Configures providers using a service account JSON key file
#   - Extracts reusable values from credentials for downstream use
#
# NOTES:
#   - Credentials are loaded from a local JSON file (do not commit to source)
#   - All resources inherit these provider configurations by default
# ===============================================================================


# ===============================================================================
# TERRAFORM PROVIDER REQUIREMENTS
# ===============================================================================
# - Locks provider sources and major versions for repeatable builds
# - Prevents accidental upgrades that may introduce breaking changes
# ===============================================================================
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4"
    }
  }
}


# ===============================================================================
# GOOGLE CLOUD PROVIDER CONFIGURATION
# ===============================================================================
# - Primary Google Cloud provider
# - Authenticates using a service account JSON key file
# - Project ID is derived from decoded credentials (avoids hardcoding)
# ===============================================================================
provider "google" {
  project     = local.credentials.project_id
  credentials = file("../credentials.json")
}


# ===============================================================================
# GOOGLE BETA PROVIDER CONFIGURATION
# ===============================================================================
# - Beta provider for preview / newer GCP resources
# - Uses the same project and credentials as the primary provider
# ===============================================================================
provider "google-beta" {
  project     = local.credentials.project_id
  credentials = file("../credentials.json")
}

# ===============================================================================
# LOCAL VARIABLES: PARSE SERVICE ACCOUNT CREDENTIALS
# ===============================================================================
# - Decodes the service account JSON file into a reusable object
# - Extracts common fields for use in IAM bindings and labeling
# ===============================================================================
locals {
  credentials = jsondecode(file("../credentials.json"))

  service_account_email = local.credentials.client_email
}

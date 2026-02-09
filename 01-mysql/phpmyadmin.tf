# ===============================================================================
# FILE: compute.tf
# ===============================================================================
# Deploys a lightweight Ubuntu VM to host phpMyAdmin (or similar admin tooling).
#
# This module:
#   - Provisions an Ubuntu 24.04 VM in the MySQL VPC/subnet
#   - Assigns a public IP for browser access and SSH administration
#   - Injects MySQL connection details via a startup script template
#   - Applies firewall tags to match HTTP/SSH firewall rules
#   - Attaches a service account for controlled API access
#
# NOTES:
#   - This VM is internet reachable; restrict firewall source ranges in production
#   - cloud-platform scope is broad; tighten scopes/permissions for production
# ===============================================================================


# ===============================================================================
# COMPUTE INSTANCE: PHPMYADMIN VM (UBUNTU 24.04)
# ===============================================================================
# - Hosts phpMyAdmin and related tooling
# - Uses a startup script to configure access to the MySQL instance
# ===============================================================================
resource "google_compute_instance" "phpmyadmin_vm" {
  name         = "phpmyadmin-vm"
  machine_type = "e2-small"
  zone         = "us-central1-a"


  # =============================================================================
  # BOOT DISK
  # =============================================================================
  # - Boots from the latest Ubuntu 24.04 LTS image in the selected family
  # =============================================================================
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_latest.self_link
    }
  }


  # =============================================================================
  # NETWORK INTERFACE
  # =============================================================================
  # - Attaches to the custom VPC/subnet
  # - access_config enables an external IP for public connectivity
  # =============================================================================
  network_interface {
    network    = google_compute_network.mysql_vpc.id
    subnetwork = google_compute_subnetwork.mysql_subnet.id

    access_config {}
  }


  # =============================================================================
  # STARTUP SCRIPT
  # =============================================================================
  # - Renders a local template file and injects MySQL connection parameters
  # - Template should install phpMyAdmin and configure connectivity
  # =============================================================================
  metadata_startup_script = templatefile("./scripts/phpmyadmin.sh.template", {
    PASSWORD   = random_password.mysql.result,
    MYSQL_HOST = "mysql.internal.mysql-zone.local"
    USER       = "sysadmin"
  })


  # =============================================================================
  # FIREWALL TAGS
  # =============================================================================
  # - Tags must match firewall rule target_tags to allow SSH/HTTP
  # =============================================================================
  tags = [
    "mysql-allow-ssh",
    "mysql-allow-http"
  ]


  # =============================================================================
  # SERVICE ACCOUNT
  # =============================================================================
  # - Attaches a service account identity for Google API access
  # - Scopes are broad for simplicity; tighten for production use
  # =============================================================================
  service_account {
    email  = local.credentials.client_email
    scopes = ["cloud-platform"]
  }


  # =============================================================================
  # DEPENDENCIES
  # =============================================================================
  # - Ensures the database exists before the VM startup script runs
  # =============================================================================
  depends_on = [
    google_sql_database_instance.mysql
  ]
}


# ===============================================================================
# DATA SOURCE: UBUNTU 24.04 LTS IMAGE
# ===============================================================================
# - Resolves the latest Ubuntu 24.04 LTS image from the official project
# - Using the family ensures patch updates are automatically selected
# ===============================================================================
data "google_compute_image" "ubuntu_latest" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

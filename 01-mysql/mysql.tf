# ===============================================================================
# FILE: mysql.tf
# ===============================================================================
# Provisions a private Google Cloud SQL MySQL instance and supporting resources.
#
# This module:
#   - Creates a MySQL 8.0 Cloud SQL instance with private IP only
#   - Configures backups and a defined maintenance window
#   - Creates a SQL admin user with a generated password
#   - Exposes the database via private Cloud DNS
#   - Enforces ordering to avoid VPC peering race conditions
#
# NOTES:
#   - Public IP access is explicitly disabled
#   - Deletion protection is off for non-production use
# ===============================================================================


# ===============================================================================
# CLOUD SQL INSTANCE: MYSQL
# ===============================================================================
# - Managed MySQL 8.0 database using private networking only
# - Attached to a custom VPC via Private Service Access
# - Includes backup and maintenance policies
# ===============================================================================
resource "google_sql_database_instance" "mysql" {
  name             = "mysql-instance"
  database_version = "MYSQL_8_0"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.mysql_vpc.self_link
    }

    backup_configuration {
      enabled = true
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
  }

  deletion_protection = false

  depends_on = [
    null_resource.wait_for_vpc_peering
  ]
}


# ===============================================================================
# CLOUD SQL USER: MYSQL ADMIN
# ===============================================================================
# - Creates a SQL-level administrative user
# - Password is generated dynamically via random_password
# ===============================================================================
resource "google_sql_user" "mysql_user" {
  name     = "sysadmin"
  instance = google_sql_database_instance.mysql.name
  host     = "%"
  password = random_password.mysql.result
}


# ===============================================================================
# PRIVATE DNS ZONE: INTERNAL MYSQL
# ===============================================================================
# - Enables internal name resolution for the database
# - Avoids hardcoding private IP addresses in clients
# - Scoped to the MySQL VPC only
# ===============================================================================
resource "google_dns_managed_zone" "private_dns" {
  name       = "internal-mysql-zone"
  dns_name   = "internal.mysql-zone.local."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.mysql_vpc.id
    }
  }

  description = "Private DNS zone for internal MySQL resolution"
}


# ===============================================================================
# PRIVATE DNS RECORD: MYSQL A RECORD
# ===============================================================================
# - Maps a friendly hostname to the database private IP
# - Used by internal clients for consistent connectivity
# ===============================================================================
resource "google_dns_record_set" "mysql_dns" {
  name         = "mysql.internal.mysql-zone.local."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private_dns.name

  rrdatas = [
    google_sql_database_instance.mysql.private_ip_address
  ]
}


# ===============================================================================
# WAIT RESOURCE: VPC PEERING PROPAGATION
# ===============================================================================
# - Forces a delay to ensure Private Service Access is ready
# - Prevents Cloud SQL creation failures due to race conditions
# - Multiple GCP control planes must converge before private IP can be used.
# - Doesn't appear to be an effective way to poll this
# ===============================================================================
resource "null_resource" "wait_for_vpc_peering" {
  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  provisioner "local-exec" {
    command = "echo 'NOTE: Waiting for VPC peering propagation' && sleep 300"
  }
}

# ===============================================================================
# FILE: network.tf
# ===============================================================================
# Creates the private networking foundation for MySQL resources.
#
# This module:
#   - Creates a custom VPC with explicit subnet planning
#   - Creates a regional subnet for compute and supporting services
#   - Adds basic firewall rules for HTTP and SSH access
#   - Allocates an internal IP range for Private Service Access
#   - Establishes a service networking connection for Cloud SQL private IP
#
# NOTES:
#   - Firewall rules using 0.0.0.0/0 are not production safe
#   - Tighten source ranges and use tags where possible
# ===============================================================================


# ===============================================================================
# VPC NETWORK: MYSQL
# ===============================================================================
# - Custom VPC to isolate MySQL-related resources
# - Disables auto subnet creation to enforce IP address planning
# ===============================================================================
resource "google_compute_network" "mysql_vpc" {
  name                    = "mysql-vpc"
  auto_create_subnetworks = false
}


# ===============================================================================
# SUBNET: MYSQL
# ===============================================================================
# - Regional subnet used by compute resources and supporting services
# - Region should align with Cloud SQL and VM placements
# ===============================================================================
resource "google_compute_subnetwork" "mysql_subnet" {
  name          = "mysql-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.mysql_vpc.id
}


# ===============================================================================
# FIREWALL RULE: ALLOW INBOUND HTTP
# ===============================================================================
# - Allows inbound TCP/80 for web-based tooling (e.g., admin UI)
# - Open to the internet by default; restrict in production
# ===============================================================================
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.mysql_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}


# ===============================================================================
# FIREWALL RULE: ALLOW INBOUND SSH
# ===============================================================================
# - Allows inbound TCP/22 for VM administration
# - Uses target_tags to scope access to specific instances
# ===============================================================================
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.mysql_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}


# ===============================================================================
# PRIVATE SERVICE ACCESS: INTERNAL IP RANGE
# ===============================================================================
# - Reserves an internal CIDR range used for managed service networking
# - Required for Cloud SQL private IP via Service Networking (VPC peering)
# ===============================================================================
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.mysql_vpc.id
}


# ===============================================================================
# PRIVATE SERVICE ACCESS: SERVICE NETWORKING CONNECTION
# ===============================================================================
# - Creates the peering connection to Google managed services
# - Enables Cloud SQL to receive a private address in the VPC
#
# NOTE:
#   - Uses google-beta provider due to a known provider issue/workaround
# ===============================================================================
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.mysql_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]

  provider = google-beta
}

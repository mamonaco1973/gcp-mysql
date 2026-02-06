# ===============================================================================
# FILE: credentials.tf
# ===============================================================================
# Generates and securely stores MySQL credentials using Google Secret Manager.
#
# WORKFLOW:
#   1. Generate a strong random password (alphanumeric only).
#   2. Create a Secret Manager secret to hold MySQL credentials.
#   3. Store the username and password as a JSON secret version.
#
# NOTES:
#   - Passwords are never hardcoded or stored in plaintext in Terraform code.
#   - Secrets are retrieved securely at runtime via IAM-controlled access.
# ===============================================================================


# ===============================================================================
# GENERATE RANDOM PASSWORD FOR MYSQL USER
# ===============================================================================
# - Generates a 24-character alphanumeric password
# - Special characters are disabled for shell and tooling compatibility
# - Used exclusively for secure service authentication
# ===============================================================================
resource "random_password" "mysql" {
  length  = 24    # Strong entropy: 24-character password
  special = false # Avoid special characters for scripting compatibility
}


# ===============================================================================
# CREATE SECRET IN GOOGLE SECRET MANAGER
# ===============================================================================
# - Creates a managed secret for MySQL credentials
# - Prevents hardcoding credentials in Terraform or source control
# - Uses Google-managed replication for high availability
# ===============================================================================
resource "google_secret_manager_secret" "mysql_secret" {
  secret_id = "mysql-credentials"

  replication {
    auto {} # Default Google-managed replication
  }
}


# ===============================================================================
# ADD SECRET VERSION WITH CREDENTIAL DATA
# ===============================================================================
# - Writes the actual secret payload to Secret Manager
# - Stores credentials as a structured JSON object
# - Consumable by service accounts, VMs, and workloads at runtime
# ===============================================================================
resource "google_secret_manager_secret_version" "mysql_secret_version" {
  secret = google_secret_manager_secret.mysql_secret.id

  secret_data = jsonencode({
    username = "sysadmin"
    password = random_password.mysql.result
  })
}

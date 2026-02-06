#!/bin/bash
# ===============================================================================
# FILE: destroy.sh
# ===============================================================================
# Tears down all MySQL-related Google Cloud infrastructure.
#
# This script:
#   - Validates the local environment and credentials
#   - Deletes the Cloud SQL MySQL instance via gcloud
#   - Destroys all remaining Terraform-managed resources
#   - Performs a clean, ordered teardown
#
# DANGER:
#   - This operation is destructive and irreversible
#   - All database data and supporting infrastructure will be deleted
#
# FAIL FAST:
#   - Any command failure causes immediate exit
# ===============================================================================


# ------------------------------------------------------------------------------
# STRICT SHELL BEHAVIOR
# ------------------------------------------------------------------------------
#  -e  Exit immediately on error
#  -u  Treat unset variables as errors
#  -o pipefail  Fail pipelines if any command fails
# ------------------------------------------------------------------------------
set -euo pipefail


# ===============================================================================
# VALIDATE ENVIRONMENT
# ===============================================================================
# - Ensures required tools, credentials, and APIs are available
# - check_env.sh is expected to fail on error
# ===============================================================================
./check_env.sh


# ===============================================================================
# DESTROY CLOUD SQL MYSQL INSTANCE
# ===============================================================================
# - Explicitly deletes the Cloud SQL instance
# - --quiet suppresses interactive confirmation prompts
# ===============================================================================
gcloud sql instances delete mysql-instance --quiet


# ===============================================================================
# DESTROY TERRAFORM-MANAGED RESOURCES
# ===============================================================================
# - Destroys all remaining infrastructure defined in Terraform
# - Includes networking, DNS, and supporting compute resources
# ===============================================================================
cd 01-mysql

terraform init
terraform destroy -auto-approve

cd ..

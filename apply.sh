#!/bin/bash
# ===============================================================================
# FILE: apply.sh
# ===============================================================================
# Orchestrates the end-to-end deployment of the MySQL infrastructure stack.
#
# This script:
#   - Validates the local environment and credentials
#   - Initializes and applies Terraform configuration
#   - Returns to the project root on completion
#   - Runs post-deployment validation
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
# DEPLOY MYSQL INFRASTRUCTURE
# ===============================================================================
# - Initializes and applies Terraform configuration for Cloud SQL resources
# ===============================================================================
cd 01-mysql

terraform init
terraform apply -auto-approve

cd ..


# ===============================================================================
# POST-DEPLOYMENT VALIDATION
# ===============================================================================
# - Verifies deployed resources and prints final access information
# ===============================================================================
echo ""
./validate.sh

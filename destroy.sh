#!/bin/bash

# =================================================================================
# VALIDATE ENVIRONMENT
# - Ensures prerequisites are in place before proceeding
# =================================================================================

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# =================================================================================
# DESTROY MYSQL INFRASTRUCTURE
# - Step-by-step teardown of Cloud SQL resources
# - Partial destroy first (user + instance), then full cleanup
# =================================================================================

gcloud sql instances delete mysql-instance --quiet

cd 01-mysql
terraform init
terraform destroy -auto-approve
cd ..

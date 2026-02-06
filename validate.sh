#!/bin/bash
# ===============================================================================
# FILE: validate.sh
# ===============================================================================
# Resolves and prints the phpMyAdmin endpoint and the internal MySQL DNS name.
# Also waits for phpMyAdmin to become reachable before returning success.
#
# OUTPUT (SUMMARY):
#   - phpMyAdmin URL
#   - MySQL internal hostname
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
# CONFIGURATION
# ===============================================================================
PHPMYADMIN_INSTANCE_NAME="phpmyadmin-vm"
PHPMYADMIN_ZONE="us-central1-a"

MYSQL_DNS_NAME="mysql.internal.mysql-zone.local"

MAX_ATTEMPTS=30
SLEEP_SECONDS=30


# ===============================================================================
# RESOLVE PHPMYADMIN PUBLIC IP
# ===============================================================================
PHPMYADMIN_IP="$(gcloud compute instances describe "${PHPMYADMIN_INSTANCE_NAME}" \
  --zone="${PHPMYADMIN_ZONE}" \
  --format="value(networkInterfaces[0].accessConfigs[0].natIP)")"

if [[ -z "${PHPMYADMIN_IP}" ]]; then
  echo "ERROR: Failed to resolve phpMyAdmin public IP address." >&2
  exit 1
fi

PHPMYADMIN_URL="http://${PHPMYADMIN_IP}"

echo "NOTE: phpMyAdmin running at ${PHPMYADMIN_URL}"


# ===============================================================================
# WAIT FOR PHPMYADMIN TO BECOME REACHABLE
# ===============================================================================
echo "NOTE: Waiting for phpMyAdmin to become available at ${PHPMYADMIN_URL}..."

ATTEMPT=1
until curl -s --head --fail "${PHPMYADMIN_URL}" >/dev/null; do
  if [[ "${ATTEMPT}" -ge "${MAX_ATTEMPTS}" ]]; then
    echo "ERROR: phpMyAdmin did not become available after ${MAX_ATTEMPTS} attempts." \
      >&2
    exit 1
  fi

  echo "WARNING: phpMyAdmin not reachable. Retrying in ${SLEEP_SECONDS}s..." >&2
  sleep "${SLEEP_SECONDS}"
  ATTEMPT=$((ATTEMPT + 1))
done


# ===============================================================================
# FINAL OUTPUT (CONSISTENT SUMMARY)
# ===============================================================================
echo ""
echo "===============================================================================" 
echo "BUILD RESULTS"
echo "===============================================================================" 
echo "phpMyAdmin URL        : ${PHPMYADMIN_URL}"
echo "MySQL Hostname (DNS)  : ${MYSQL_DNS_NAME}"
echo "===============================================================================" 

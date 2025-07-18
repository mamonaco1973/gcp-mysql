#!/bin/bash

#-------------------------------------------------------------------------------
# Output phpmyadmin URL and mysql DNS name
#-------------------------------------------------------------------------------

 PHPMYADMIN_IP=$(gcloud compute instances describe phpmyadmin-vm \
   --zone=us-central1-a \
   --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

echo "NOTE: phpMyAdmin running at http://$PHPMYADMIN_IP"

# Wait until the phpMyAdmin URL is reachable (HTTP 200 or similar)
echo "NOTE: Waiting for phpMyAdmin to become available at http://$PHPMYADMIN_IP ..."

# Max attempts (optional)
MAX_ATTEMPTS=30
ATTEMPT=1

until curl -s --head --fail "http://$PHPMYADMIN_IP" > /dev/null; do
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "ERROR: phpMyAdmin did not become available after $MAX_ATTEMPTS attempts."
    exit 1
  fi
  echo "WARNING: phpMyAdmin not yet reachable. Retrying in 30 seconds..."
  sleep 30
  ATTEMPT=$((ATTEMPT+1))
done


MYSQL_DNS="mysql.internal.mysql-zone.local"
echo "NOTE: Hostname for mysql server is \"$MYSQL_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------

#!/bin/bash

#-------------------------------------------------------------------------------
# Output pgweb URL and postgres DNS name
#-------------------------------------------------------------------------------

 PHPMYADMIN_IP=$(gcloud compute instances describe phpmyadmin-vm \
   --zone=us-central1-a \
   --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

echo "NOTE: phpMyAdmin running at http://$PHPMYADMIN_IP"

MYSQL_DNS="mysql.internal.db-zone.local"
echo "NOTE: Hostname for mysql server is \"$MYSQL_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------

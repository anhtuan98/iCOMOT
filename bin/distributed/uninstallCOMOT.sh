#!/bin/sh

echo "Removing mela-analysis-service"
sudo -S service mela-analysis-service stop
sudo -S rm /etc/init.d/mela-analysis-service
sudo -S update-rc.d -f mela-analysis-service remove

echo "Removing mela-analysis-service"
sudo -S service mela-cost-service stop
sudo -S rm /etc/init.d/mela-cost-service
sudo -S update-rc.d -f mela-cost-service remove

echo "Removing mela-data-service"
sudo -S service mela-data-service stop
sudo -S rm /etc/init.d/mela-data-service
sudo -S update-rc.d -f mela-data-service remove
 
echo "Removing rSYBL-service"
sudo -S service rSYBL-service stop
sudo -S rm /etc/init.d/rSYBL-service
sudo -S update-rc.d -f rSYBL-service remove
sudo -S rm -rf ./rSYBL  

echo "Removing salsa-engine"
sudo -S service salsa-engine-service stop
sudo -S rm /etc/init.d/salsa-engine-service 
sudo -S update-rc.d salsa-engine-service remove  
sudo -S rm -rf ./SALSA  

echo "Removing elise-engine"
sudo -S service elise-service stop
sudo -S rm /etc/init.d/elise-service 
sudo -S update-rc.d elise-service remove  
sudo -S rm -rf ./ELISE  
sudo -S rm -f /usr/bin/elise-client

echo "Removing comot-dashboard-service"
sudo -S service comot-dashboard-service stop
sudo -S rm /etc/init.d/comot-dashboard-service
sudo -S update-rc.d -f comot-dashboard-service remove
sudo -S rm -rf ./comot-*

echo "Removing ganglia"
sudo -S apt-get remove ganglia-monitor gmetad -y

echo "Remove iCOMOT service script"
sudo -S rm /etc/init.d/icomot-services
sudo -S update-rc.d -f icomot-services remove

sudo -S rm -rf ./workspace

REPOSITORY=/var/www/html/iCOMOTTutorial/

sudo -S rm -rf $REPOSITORY
sudo -S apt-get remove apache2 php5 -y

sudo -S ifconfig lo:0 down


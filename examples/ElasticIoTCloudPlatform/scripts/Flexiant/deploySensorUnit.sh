#!/bin/bash
# This small steps move sensor artifact to the place
# assume that the sensor.tar.gz is downloaded in the same folder


#get capability for deregistering from GovOps
wget http://128.130.172.215/salsa/upload/files/rtGovOps/decommission

sudo -S cp ./decommission /bin/decommission
sudo -S chmod +x /bin/decommission

mkdir /tmp/sensor
mv ./sensor /tmp/sensor
cd /tmp/sensor
touch sensor.pid
chmod 777 sensor.pid

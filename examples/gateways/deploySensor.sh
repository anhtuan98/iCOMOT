#!/bin/bash
# This small steps install sensors artifacts into the gateway
# Following files must be present in the same folder
#  + sensor.tar.gz
#  + decommision

sudo -S cp ./decommission /bin/decommission
sudo -S chmod +x /bin/decommission

mkdir /tmp/sensor
mv ./sensor.tar.gz /tmp/sensor
cd /tmp/sensor
tar -xvzf ./sensor.tar.gz
touch sensor.pid
chmod 777 sensor.pid

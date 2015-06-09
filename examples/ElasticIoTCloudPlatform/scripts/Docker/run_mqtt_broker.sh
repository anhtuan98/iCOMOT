#!/bin/bash
#cd "/home/ubuntu"
sudo tar -xzf ./chef-mqtt_broker.tar.gz >> /tmp/salsa.artifact.log
sudo echo "Untarred mqttbroker " >> /tmp/salsa.artifact.log
sudo chef-solo -c ./chef-mqtt_broker/solo.rb >> /tmp/salsa.artifact.log

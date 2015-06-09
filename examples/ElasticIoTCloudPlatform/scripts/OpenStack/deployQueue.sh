#!/bin/bash
sudo -S apt-get install activemq -y
sudo -S ln -s /etc/activemq/instances-available/main /etc/activemq/instances-enabled/main

IP=`ifconfig eth0 | grep -o 'inet addr:[0-9.]*' | grep -o [0-9.]*`

eval "sed -i 's#127.0.0.1#$IP#' /etc/activemq/instances-enabled/main/activemq.xml"

sudo -S service activemq restart
 

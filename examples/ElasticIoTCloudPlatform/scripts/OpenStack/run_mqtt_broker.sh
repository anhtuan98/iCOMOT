#!/bin/bash
cd "/home/ubuntu"
#sudo wget "http://128.130.172.215/salsa/upload/files/DaasService/IoT/solo-install.sh"
#sudo chmod +x ./solo-install.sh
#sudo ./solo-install.sh >> /tmp/salsa.artifact.log
#sudo wget "http://128.130.172.215/salsa/upload/files/DaasService/IoT/chef-mqtt_broker.tar.gz" >> /tmp/salsa.artifact.log
#sudo tar -xzf ./chef-mqtt_broker.tar.gz >> /tmp/salsa.artifact.log
#sudo echo "Untarred mqttbroker " >> /tmp/salsa.artifact.log
#sudo chef-solo -c ./chef-mqtt_broker/solo.rb >> /tmp/salsa.artifact.log

sudo apt-get install openjdk-7-jre-headless -yq
sudo wget -q http://apache-mirror.rbc.ru/pub/apache/activemq/5.10.2/apache-activemq-5.10.2-bin.tar.gz
sudo tar -xvzf apache-activemq-5.10.2-bin.tar.gz
sudo  ln -sf ./apache-activemq-5.10.2/bin/activemq /etc/init.d

sudo ./apache-activemq-5.10.2/bin/activemq setup /etc/default/activemq

sudo ./apache-activemq-5.10.2/bin/activemq start

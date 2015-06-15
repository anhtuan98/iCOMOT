#!/bin/bash
#cd "/home/ubuntu"
#sudo tar -xzf ./chef-mqtt_broker.tar.gz >> /tmp/salsa.artifact.log
#sudo echo "Untarred mqttbroker " >> /tmp/salsa.artifact.log
#sudo chef-solo -c ./chef-mqtt_broker/solo.rb >> /tmp/salsa.artifact.log

sudo apt-get install openjdk-7-jre-headless -y
sudo wget http://apache-mirror.rbc.ru/pub/apache/activemq/5.10.2/apache-activemq-5.10.2-bin.tar.gz
sudo tar -xvzf apache-activemq-5.10.2-bin.tar.gz
sudo  ln -sf ./apache-activemq-5.10.2/bin/activemq /etc/init.d

sudo ./apache-activemq-5.10.2/bin/activemq setup /etc/default/activemq

sudo ./apache-activemq-5.10.2/bin/activemq start

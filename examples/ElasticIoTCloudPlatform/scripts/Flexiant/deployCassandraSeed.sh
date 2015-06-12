#!/bin/bash

echo "Installing cassandra head node \n" >> /tmp/salsa.artifact.log
tar -xzf ./ElasticCassandraSetup-1.0.tar.gz 
cd ./ElasticCassandraSetup-1.0 
IP=`ifconfig eth0 | grep -o 'inet addr:[0-9.]*' | grep -o [0-9.]*`
H=$(hostname)
echo "$IP $H" | sudo -S tee -a /etc/hosts

./setupCassandra.sh >> /tmp/salsa.artifact.log
./setupElasticCassandraController.sh >> /tmp/salsa.artifact.log
cd ./gangliaPlugIns
./setupPlugIns.sh >> /tmp/salsa.artifact.log

#used in unicast
GANGLIA_IP=109.231.126.63

sudo -S service ganglia-monitor stop

#delete all joins on multicast
eval "sed -i 's/host = .*//' /etc/ganglia/gmond.conf"
eval "sed -i 's/mcast_join.*//' /etc/ganglia/gmond.conf"
#add unicast host destination
eval "sed -i 's#udp_send_channel {.*#udp_send_channel { \n host = $GANGLIA_IP#' /etc/ganglia/gmond.conf"
#delete the bind on multicast for receive
eval "sed -i 's/bind.*//' /etc/ganglia/gmond.conf"


sudo -S service cassandra start
sudo -S service ganglia-monitor restart

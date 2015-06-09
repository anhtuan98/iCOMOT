#!/bin/bash

echo "Installing cassandra head node \n" >> /tmp/salsa.artifact.log

. /etc/environment

#used in unicast
GANGLIA_IP=109.231.121.91

IP=`ifconfig eth0 | grep -o 'inet addr:[0-9.]*' | grep -o [0-9.]*`
H=$(hostname)
echo "$IP $H" | sudo -S tee -a /etc/hosts

echo "Get the Seed ip: $dataNodeToDataController_IP" >> /mp/salsa.artifact.log
tar -xzf ./ElasticCassandraSetup-1.0.tar.gz
cd ./ElasticCassandraSetup-1.0

./setupCassandra.sh >> /tmp/salsa.artifact.log
./setupElasticCassandraNode.sh >> /tmp/salsa.artifact.log
cd ./gangliaPlugIns

./setupPlugIns.sh >> /tmp/salsa.artifact.log

#configure GAnglia for Flexiant

sudo -S service ganglia-monitor stop

#delete all joins on multicast
eval "sed -i 's/mcast_join.*//' /etc/ganglia/gmond.conf"
#add unicast host destination
eval "sed -i 's#udp_send_channel {.*#udp_send_channel { \n host = $GANGLIA_IP#' /etc/ganglia/gmond.conf"
#delete the bind on multicast for receive
eval "sed -i 's/bind.*//' /etc/ganglia/gmond.conf"



#configure ganglia on port 8649
sudo -S service ganglia-monitor start
sudo -S service joinRing start


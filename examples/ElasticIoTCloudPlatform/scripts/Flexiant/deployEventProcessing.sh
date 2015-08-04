#!/bin/bash


echo "Installing Event Processing \n" >> /tmp/salsa.artifact.log

. /etc/environment
 
tar -xzf ./DaaS-1.0.tar.gz
cd ./DaaS-1.0

CURRENT_DIR=$(pwd)
 
CASSANDRA_SEED_IP=$eventProcessingToDataController_IP
AMQP_IP=$eventProcessingToMOM_IP
LoadBalancerIP=$eventProcessingToLoadBalancer_IP

#PROFILES="CASSANDRA,MOM"
PROFILES=CASSANDRA,MOM
AMQP_PORT=9124
AMQP_QUEUE_NAME=DB_LOG

#set event-processing current dir
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR#' $CURRENT_DIR/event-processing"
eval "sed -i 's#LoadBalancerIP=.*#LoadBalancerIP=$LoadBalancerIP#' $CURRENT_DIR/event-processing"
eval "sed -i 's#CassandraNode\.IP=.*#CassandraNode\.IP=$CASSANDRA_SEED_IP#' $CURRENT_DIR/config/daas.properties"
eval "sed -i 's#AMQP\.IP=.*#AMQP.IP=$AMQP_IP#' $CURRENT_DIR/config/daas.properties"
eval "sed -i 's#AMQP\.PORT=.*#AMQP.PORT=$AMQP_PORT#' $CURRENT_DIR/config/daas.properties"
eval "sed -i 's#AMQP\.QUEUE_NAME=.*#AMQP.QUEUE_NAME=$AMQP_QUEUE_NAME#' $CURRENT_DIR/config/daas.properties"
eval "sed -i 's#PROFILES=.*#PROFILES=\"$PROFILES\"#' $CURRENT_DIR/event-processing"

sudo -S cp ./event-processing /etc/init.d/event-processing
sudo -S chmod +x /etc/init.d/event-processing
sudo -S update-rc.d event-processing defaults

sudo service event-processing start

cd ./gangliaPlugIns
bash ./setupPlugIns.sh

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
eval "sed -i 's/send_metadata_interval.*/send_metadata_interval = 30/' /etc/ganglia/gmond.conf"



sudo -S service ganglia-monitor restart

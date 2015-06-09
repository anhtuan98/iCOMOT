#!/bin/bash

echo "Installing mqtt client which sends data to m2m \n" >> /tmp/salsa.artifact.log

USER_HOME='\home\ubuntu'
CURRENT_DIR=$(pwd)

echo "Untaring jre"
sudo tar -xzf ./jre-7-linux-x64.tar.gz

#download local service

sudo tar -xzf ./LocalDataAnalysis.tar.gz

#download and setup Oracle JDK (works better with Cassandra)
CURRENT_DIR=$(pwd)
LOCAL_SERVICE_HOME=$CURRENT_DIR/LocalDataAnalysis
JAVA_HOME=$CURRENT_DIR/jre1.7.0

if [ -z "$HOME" ] 
  then 
      echo "HOME not specified. Using "$USER_HOME;
      HOME = $USER_HOME;
fi

sudo -S chmod 0777 ./LocalDataAnalysis/local-processing-service

#Set user HOME directory
eval "sed -i 's#\<SERVICE_DIR=.*#SERVICE_DIR=$CURRENT_DIR/LocalDataAnalysis#' $CURRENT_DIR/LocalDataAnalysis/local-processing-service"

#Set user CASSANDRA HOME directory
eval "sed -i 's#\<JAVA_HOME=.*#JAVA_HOME=$JAVA_HOME#' $CURRENT_DIR/LocalDataAnalysis/local-processing-service"

cd $CURRENT_DIR/LocalDataAnalysis
sudo -S $CURRENT_DIR/LocalDataAnalysis/local-processing-service start

sudo -S service ganglia-monitor stop

cd $CURRENT_DIR/LocalDataAnalysis/gangliaPlugIns
./setupPlugIns.sh

#used in unicast
GANGLIA_IP=109.231.121.91

#delete all joins on multicast
eval "sed -i 's/mcast_join.*//' /etc/ganglia/gmond.conf"
#add unicast host destination
eval "sed -i 's#udp_send_channel {.*#udp_send_channel { \n host = $GANGLIA_IP#' /etc/ganglia/gmond.conf"
#delete the bind on multicast for receive
eval "sed -i 's/bind.*//' /etc/ganglia/gmond.conf"

 
sudo -S service ganglia-monitor start

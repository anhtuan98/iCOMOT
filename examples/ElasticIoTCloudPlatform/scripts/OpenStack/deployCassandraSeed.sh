#!/bin/bash

echo "Installing cassandra head node \n" >> /tmp/salsa.artifact.log
 
#get http://128.130.172.215/iCOMOTTutorial/files/ElasticIoTPlatform/ElasticCassandraSetup-1.0.tar.gz
tar -xzf ./ElasticCassandraSetup-1.0.tar.gz
cd ./ElasticCassandraSetup-1.0 

sudo -S chmod +x ./setupCassandra.sh
sudo -S chmod +x ./setupElasticCassandraController.sh
./setupCassandra.sh >> /tmp/salsa.artifact.log
./setupElasticCassandraController.sh >> /tmp/salsa.artifact.log
cd ./gangliaPlugIns
sudo -S chmod +x ./setupPlugIns.sh
./setupPlugIns.sh >> /tmp/salsa.artifact.log

sudo -S service cassandra start
sudo -S service ganglia-monitor restart

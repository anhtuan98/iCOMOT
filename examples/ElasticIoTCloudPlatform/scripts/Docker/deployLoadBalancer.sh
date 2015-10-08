#!/bin/bash

echo "Installing Load balancing \n" >> /tmp/salsa.artifact.log
tar -xzf ./HAProxySetup-1.0.tar.gz
cd ./HAProxySetup-1.0
CURRENT_DIR=$(pwd)

#please uncomment if needed as appropriate for your distro. otherwise HAProxy 1.4 will be installed which does not work with our ganglia plug-in

#for Ubuntu devel, lucid, precise, saucy
sudo -S add-apt-repository ppa:vbernat/haproxy-1.5 -y

#for Ubuntu  raring, quantal, precise, oneiric 
#sudo -S add-apt-repository ppa:nilya/haproxy-1.5

sudo -S apt-get update
sudo -S apt-get install curl ganglia-monitor gmond haproxy python python-pip -y
#sudo -S apt-get install python-virtualenv -y 
sudo -S pip install Flask

#set HAProxy config path in 
eval "sed -i 's#HAPROXY_CONFIG_FILE=.*#HAPROXY_CONFIG_FILE=\"$CURRENT_DIR/haproxyConfig\"#' $CURRENT_DIR/configPythonRESTfulAPI.py"
#eval "sed -i 's#HAPROXY_CONFIG_FILE=.*#HAPROXY_CONFIG_FILE=\"$CURRENT_DIR/haproxyConfig\"#' $CURRENT_DIR/load-balancer"

#copy scripts for registering and deregistering to HAPROXY in /bin
#sudo -S chmod +x $CURRENT_DIR/registerToHAProxy.sh
#sudo -S chmod +x $CURRENT_DIR/deregisterToHAProxy.sh
#sudo -S cp $CURRENT_DIR/registerToHAProxy.sh /bin/registerToHAProxy
#sudo -S cp $CURRENT_DIR/deregisterToHAProxy.sh /bin/deregisterToHAProxy

sudo -S killall haproxy

%haproxy -f $CURRENT_DIR/haproxyConfig
python ./configPythonRESTfulAPI.py  &
curl -X DELETE http://localhost:5001/service/1/1

cd ./gangliaPlugIns
chmod +x ./setupPlugIns.sh
./setupPlugIns.sh

#used in unicast
GANGLIA_IP=192.1.1.15

sudo -S service ganglia-monitor stop

#delete all joins on multicast
eval "sed -i 's/mcast_join.*//' /etc/ganglia/gmond.conf"
#add unicast host destination
eval "sed -i 's#udp_send_channel {.*#udp_send_channel { \n host = $GANGLIA_IP#' /etc/ganglia/gmond.conf"
#delete the bind on multicast for receive
eval "sed -i 's/bind.*//' /etc/ganglia/gmond.conf"
eval "sed -i 's/send_metadata_interval.*/send_metadata_interval = 30/' /etc/ganglia/gmond.conf"

sudo -S service ganglia-monitor restart

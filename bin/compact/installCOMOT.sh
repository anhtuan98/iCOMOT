#!/bin/bash

#if comot deployed remotely, please change the IP below to one publicly accessible (e.g., floating IP)
HOST_IP=localhost

echo ""
echo "#############################################################"
echo "" 
echo 'Is this a virtual machine/container?'
echo 'Please select 1(No) if this is the local machine, 2(Yes) if this is a separate machine, 3(Quit)'
options=("No" "Yes" "Quit")
select opt in "${options[@]}"
do
    case $opt in
         "${options[0]}")
            echo "Setting COMOT dashboard IP to $HOST_IP"
            break
            ;;
         "${options[1]}")
            if [[ -z $1 ]]
            then 
                echo "Please enter a PUBLICLY ACCESSIBLE IP for this machine/container to setup COMOT Dashboard accordingly"
                read inputIP
                HOST_IP=$(echo $inputIP | tr -d ' ') 
                echo "Setting COMOT dashboard IP to $HOST_IP"
            else
                echo "Detected argument $1. Will use for HOST_IP" 
                HOST_IP=$1 
                echo "Setting COMOT dashboard IP to $HOST_IP"
            fi 
            break
            ;;
        "${options[2]}")
            exit
            ;;
        *) echo invalid option;;
    esac
done
 

echo ""
echo "#############################################################"
echo ""

mkdir workspace
cd workspace

CURRENT_DIR=$(pwd)

##ensure we use Oracle jdk
#echo "Downloading jre"
#wget  http://128.130.172.215/iCOMOTTutorial/files/Misc/jre-7-linux-x64.tar.gz
#echo "Unpacking JRE"
#tar -xzf ./jre-7-linux-x64.tar.gz
#rm  ./jre-7-linux-x64.tar.gz
#JAVA=$CURRENT_DIR/jre1.7.0/bin/java
#eval "sed -i 's#securerandom.source=.*#securerandom.source=file:/dev/./urandom#' $CURRENT_DIR/jre1.7.0/lib/security/java.security"

#ensure we use Oracle jdk 8 to work with GovOps
echo "Downloading jre"
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jre-8u45-linux-x64.tar.gz
echo "Unpacking JRE"
tar -xzf ./jre-8u45-linux-x64.tar.gz 
rm  ./jre-8u45-linux-x64.tar.gz
JAVA=$CURRENT_DIR/jre1.8.0_45/bin/java
eval "sed -i 's#securerandom.source=.*#securerandom.source=file:/dev/./urandom#' $CURRENT_DIR/jre1.8.0_45/lib/security/java.security"

echo "Checking if Ganglia exists"

if [[ -z $(which ganglia) ]]
  then
    echo "Installing Ganglia"
    sudo -S apt-get install ganglia-monitor gmetad -y
fi

sudo -S ifconfig lo:0 192.1.1.15

echo 'Will you use this deployment with Docker?'
echo 'For Docker specific Ganglia configuration is injected, in which containers push data to a local network interface, making Ganglia unabel to monitor other VMs.'
echo 'Please select 1(No), 2(Yes)'
options=("No" "Yes" "Quit")
select opt in "${options[@]}"
do
    case $opt in
         "${options[0]}")
            GANGLIA_IP=`ifconfig eth0 | grep -o 'inet addr:[0-9.]*' | grep -o [0-9.]*`
            break
            ;;
         "${options[1]}")
            GANGLIA_IP='192.1.1.15'
            echo 'If you restart the machine please execute "sudo -S ifconfig lo:0 192.1.1.15" to bring back the unicast interface used by Ganglia with Docker'
	    sleep 5
            break
            ;;
        "${options[2]}")
            exit
            ;;
        *) echo invalid option;;
    esac
done

#delete all joins on multicast
eval "sed -i 's/mcast_join.*//' /etc/ganglia/gmond.conf"
eval "sed -i 's/host = .*//' /etc/ganglia/gmond.conf"
#add unicast host destination
eval "sed -i 's#udp_send_channel {.*#udp_send_channel { \n host = $GANGLIA_IP#' /etc/ganglia/gmond.conf"
#delete the bind on multicast for receive
eval "sed -i 's/bind.*//' /etc/ganglia/gmond.conf"
eval "sed -i 's/send_metadata_interval.*/send_metadata_interval = 30/' /etc/ganglia/gmond.conf"

########## INSTALL COMPACT iCOMOT ###########
echo "Deploying iCOMOT"
echo "Downloading iCOMOT"
wget  https://github.com/tuwiendsg/iCOMOT/blob/master/bin/compact/iCOMOT-Platform.tar.gz?raw=true -O ./iCOMOT-Platform.tar.gz
echo "Unpacking iCOMOT"
tar -xzf ./iCOMOT-Platform.tar.gz
rm  ./iCOMOT-Platform.tar.gz

#download service's last version

sudo -S wget  http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/mela/MELA-DataService/3.0-SNAPSHOT/MELA-DataService-3.0-SNAPSHOT.war -O  ./iCOMOT-Platform/webapps/MELA.war
#sudo -S wget  http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/comot/COMOT-VisualizationService/0.0.1-SNAPSHOT/COMOT-VisualizationService-0.0.1-SNAPSHOT.war -O  ./iCOMOT-Platform/webapps/iCOMOT.war
sudo -S wget  http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/cloud/salsa/salsa-engine/2.0/salsa-engine-2.0.war -O ./iCOMOT-Platform/webapps/salsa-engine.war
              
sudo -S wget  http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/mela/MELA-SpaceAndPathwayAnalysisService/3.0-SNAPSHOT/MELA-SpaceAndPathwayAnalysisService-3.0-SNAPSHOT.war -O  ./iCOMOT-Platform/webapps1/MELA-AnalysisService.war

 
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/iCOMOT-Platform/#' $CURRENT_DIR/iCOMOT-Platform/icomot-platform"
#eval "sed -i 's#JAVA_HOME=.*#JAVA_HOME=$CURRENT_DIR/jre1.7.0/#' $CURRENT_DIR/iCOMOT-Platform/icomot-platform"
eval "sed -i 's#JAVA_HOME=.*#JAVA_HOME=$CURRENT_DIR/jre1.8.0_45/#' $CURRENT_DIR/iCOMOT-Platform/icomot-platform"

#get config file for SALSA
sudo -S https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/bin/compact/cloudUserParameters.ini -O  /etc/cloudUserParameters.ini
#get latest salsa pioneer
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/cloud/salsa/salsa-pioneer/2.0/salsa-pioneer-2.0.jar -O  $CURRENT_DIR/iCOMOT-Platform/salsa-pioneer.jar

#try to get eth0 IP
if [[ -n $(ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}') ]]
  then
  LOCAL_IP=$(ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
elif [[ -n $(ifconfig wlan0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}') ]]
  then
  LOCAL_IP=$(ifconfig wlan0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
else
  LOCAL_IP="172.17.42.1"
fi

eval "sed -i 's#SALSA_CENTER_IP=.*#SALSA_CENTER_IP=$LOCAL_IP#' $CURRENT_DIR/iCOMOT-Platform/salsa.engine.properties"

eval "sed -i 's#SALSA_CENTER_WORKING_DIR=.*#SALSA_CENTER_WORKING_DIR=$CURRENT_DIR/salsa-engine#' $CURRENT_DIR/iCOMOT-Platform/salsa.engine.properties"
eval "sed -i 's#SALSA_PIONEER_WORKING_DIR=.*#SALSA_PIONEER_WORKING_DIR=$CURRENT_DIR/salsa-pioneer#' $CURRENT_DIR/iCOMOT-Platform/salsa.engine.properties"
 
mkdir $CURRENT_DIR/salsa-engine/
mkdir $CURRENT_DIR/salsa-pioneer/

chmod 0777 $CURRENT_DIR/salsa-engine/
chmod 0777 $CURRENT_DIR/salsa-pioneer/

eval "sed -i 's#HOST_IP#$HOST_IP#' $CURRENT_DIR/iCOMOT-Platform/config/modules.xml"

# current dir is workspace, inside we have ./iCOMOT-Platform
sudo -S chmod +x ./iCOMOT-Platform/icomot-platform
sudo -S cp ./iCOMOT-Platform/icomot-platform /etc/init.d/icomot-platform
sudo -S chmod +x /etc/init.d/icomot-platform
sudo -S update-rc.d icomot-platform defaults


########## INSTALL rtGovOps ###########
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/apimanager/1.0-SNAPSHOT/apimanager-1.0-SNAPSHOT.war -O ./iCOMOT-Platform/webapps/APIManager.war
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGManager/1.0-SNAPSHOT/SDGManager-1.0-SNAPSHOT.war -O ./iCOMOT-Platform/webapps/SDGManager.war
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGBalancer/1.0-SNAPSHOT/SDGBalancer-1.0-SNAPSHOT.war -O ./iCOMOT-Platform/webapps/SDGBalancer.war
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGBuilder/1.0-SNAPSHOT/SDGBuilder-1.0-SNAPSHOT.war -O ./iCOMOT-Platform/webapps/SDGBuilder.war
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/common/1.0-SNAPSHOT/common-1.0-SNAPSHOT.jar -O  ./iCOMOT-Platform/webapps/common-1.0-SNAPSHOT.jar


cd ./iCOMOT-Platform
CURRENT_DIR=$(pwd)

########## INSTALL rSYBL ###########
wget  https://github.com/tuwiendsg/iCOMOT/blob/master/bin/resources/rSYBL.tar.gz?raw=true -O ./rSYBL.tar.gz
tar -xzf ./rSYBL.tar.gz
rm ./rSYBL.tar.gz

sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/rSYBL/control-service/rSYBL-analysis-engine/1.0-SNAPSHOT/rSYBL-analysis-engine-1.0-SNAPSHOT-exec-war.jar -O  ./rSYBL/rSYBL-analysis-engine-1.0-SNAPSHOT-war-exec.jar

eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/rSYBL/rSYBL-service"
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/rSYBL#' $CURRENT_DIR/rSYBL/rSYBL-service"

sudo -S cp ./rSYBL/rSYBL-service /etc/init.d/rSYBL-service
sudo -S chmod +x /etc/init.d/rSYBL-service
sudo -S update-rc.d rSYBL-service defaults



########## INSTALL DOCKER ###########
function configureDocker() {
	echo "Configuring Docker"
	if [[ -z $(which docker) ]]
	  then
        	sudo -S apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
	        sudo -S sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
        	sudo -S apt-get -q update
	        sudo -S apt-get -q -y install linux-image-extra-`uname -r` lxc-docker
	fi
	#update docker base image
	sudo -S docker pull leduchung/salsa
}

echo " "
echo "Do you want to install DOCKER to run your application on this machine?"
echo "The installation requires ~800MB for docker image."
select yn in "Yes" "No"; do
    case $yn in
        No ) echo "ok. Docker is not installed."; break;;
        Yes ) configureDocker; break;;
    esac
done


######### INSTALL icomot-service script ##########
wget  https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/bin/compact/icomot-services
eval "sed -i 's#HOST_IP=localhost#HOST_IP=$HOST_IP#' $CURRENT_DIR/icomot-services"
sudo -S cp icomot-services /etc/init.d/icomot-services
sudo -S chmod +x /etc/init.d/icomot-services
sudo -S update-rc.d icomot-services defaults

######### INSTALL icomot-service oftware repository ##########
 
REPOSITORY=/var/www/html/iCOMOTTutorial/files/


echo " "
echo "Installing local software repository at http://$HOST_IP/iCOMOTTutorial/"
echo "Repository files on disk at $REPOSITORY"
 

sudo apt-get install apache2 php5 -y

cd /var/www/html

echo '<!DOCTYPE HTML>
<html lang="en-US">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="refresh" content="1;url=./iCOMOTTutorial/">
        <script type="text/javascript">
            window.location.href = "./iCOMOTTutorial/"
        </script>
        <title>TUW Software Repository redirection</title>
    </head>
    <body>
        If you are not redirected automatically, follow the <a href="./iCOMOTTutorial/">./iCOMOTTutorial/</a>
    </body>
</html>' | sudo -S tee -a ./index.html > /tmp/index.log

sudo -S mkdir /var/www/html/iCOMOTTutorial/
sudo -S mkdir $REPOSITORY


cd /var/www/html/iCOMOTTutorial/


sudo -S wget -q https://github.com/downloads/Studio-42/elFinder/elfinder-2.0-rc1.tar.gz
sudo -S tar -xzf ./elfinder-2.0-rc1.tar.gz
sudo -S mv ./elfinder-2.0-rc1/* ./
sudo -S mv ./elfinder.html ./index.html

#download all software artifacts from GitHub if not exist locally

 
if [ -f ../examples/ElasticIoTCloudPlatform/artifacts/DaaS-1.0.tar.gz ]; then
	sudo cp -r ../examples/ElasticIoTCloudPlatform $REPOSITORY
	sudo cp -r ../examples/Misc $REPOSITORY
        sudo -S mkdir $REPOSITORY/ManagingIoTCloudSystems
        sudo -S wget -q http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/icomot/ManagingIoTCloudSystems-Tutorial/1.0/ManagingIoTCloudSystems-Tutorial-1.0.tar.gz -P $REPOSITORY/ManagingIoTCloudSystems/
else 	

   declare -a ElasticIoTCloudPlatform_artifacts=(
        https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/artifacts/DaaS-1.0.tar.gz
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/artifacts/DaaSQueue-1.0.tar.gz
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/artifacts/ElasticCassandraSetup-1.0.tar.gz
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/artifacts/HAProxySetup-1.0.tar.gz
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/artifacts/LocalDataAnalysis.tar.gz
        https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/artifacts/apache-cassandra-1.2.6-bin.tar.gz
   )

   declare -a ElasticIoTCloudPlatform_Docker_scripts=(
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Docker/deployCassandraNode.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Docker/deployCassandraSeed.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Docker/deployEventProcessing.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Docker/deployLoadBalancer.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Docker/deployLocalAnalysis.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Docker/deployQueue.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Docker/deployWorkloadGenerator.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Docker/run_mqtt_broker.sh
   )

    declare -a ElasticIoTCloudPlatform_Flexiant_scripts=(
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployCassandraNode.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployCassandraSeed.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployEventProcessing.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployLoadBalancer.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployLocalAnalysis.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployQueue.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deploySensorUnit.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployWorkloadGenerator.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/Flexiant/run_mqtt_broker.sh
    )

    declare -a ElasticIoTCloudPlatform_OpenStack_scripts=(
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployCassandraNode.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployCassandraSeed.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployEventProcessing.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployLoadBalancer.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployLocalAnalysis.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployMoM.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployQueue.shg
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/ElasticIoTCloudPlatform/scripts/OpenStack/run_mqtt_broker.sh

    )
 declare -a MISC_artifacts=(https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/Misc/artifacts/jre-7-linux-x64.tar.gz)

  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform
  sudo -S mkdir $REPOSITORY/ManagingIoTCloudSystems
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/artifacts
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/scripts
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/scripts/Docker
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/scripts/Flexiant
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/scripts/OpenStack
  sudo -S mkdir $REPOSITORY/Misc
  sudo -S mkdir $REPOSITORY/Misc/artifacts

  sudo -S chmod +x $REPOSITORY/Misc/artifacts
  
  for i in "${ElasticIoTCloudPlatform_artifacts[@]}"
  do
     sudo -S wget -q $i -P $REPOSITORY/ElasticIoTCloudPlatform/artifacts/
  done

  for i in "${ElasticIoTCloudPlatform_Docker_scripts[@]}"
  do
     sudo -S wget -q $i -P $REPOSITORY/ElasticIoTCloudPlatform/scripts/Docker/
  done

  for i in "${ElasticIoTCloudPlatform_Flexiant_scripts[@]}"
  do
     sudo -S wget -q $i -P $REPOSITORY/ElasticIoTCloudPlatform/scripts/Flexiant/
  done

  for i in "${ElasticIoTCloudPlatform_OpenStack_scripts[@]}"
  do
     sudo -S wget -q $i -P $REPOSITORY/ElasticIoTCloudPlatform/scripts/OpenStack/
  done
 
  sudo -S wget -q https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/Misc/artifacts/jre-7-linux-x64.tar.gz -P $REPOSITORY/Misc/artifacts/ 

  sudo -S wget -q http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/icomot/ManagingIoTCloudSystems-Tutorial/1.0/ManagingIoTCloudSystems-Tutorial-1.0.tar.gz -P $REPOSITORY/ManagingIoTCloudSystems/

fi
echo -e "iCOMOT deployed. Please run: sudo service icomot-services start|stop " 
echo " "


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

JAVA=$(which java)

if [[ -z $JAVA ]]
  then
     echo "Downloading jre"
     wget  http://128.130.172.215/iCOMOTTutorial/files/Misc/jre-7-linux-x64.tar.gz
     echo "Unpacking JRE"
     tar -xzf ./jre-7-linux-x64.tar.gz
     rm  ./jre-7-linux-x64.tar.gz

     JAVA=$CURRENT_DIR/jre1.7.0/bin/java

     eval "sed -i 's#securerandom.source=.*#securerandom.source=file:/dev/./urandom#' $CURRENT_DIR/jre1.7.0/lib/security/java.security"

fi

########## INSTALL SALSA ###########
echo "Deploying SALSA"
echo "Downloading SALSA"
wget http://128.130.172.215/iCOMOTTutorial/files/iCOMOTDistributedPlatform/SALSA.tar.gz
echo "Unpacking SALSA"
tar -xzf ./SALSA.tar.gz
rm  ./SALSA.tar.gz

mkdir $CURRENT_DIR/SALSA/workspace
mkdir $CURRENT_DIR/SALSA/services
mkdir $CURRENT_DIR/SALSA/artifacts
mkdir $CURRENT_DIR/SALSA/tosca_templates

eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/SALSA/salsa-engine-service"
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/SALSA#' $CURRENT_DIR/SALSA/salsa-engine-service"

LOCAL_IP=$(ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')

eval "sed -i 's#SALSA_CENTER_IP=.*#SALSA_CENTER_IP=$LOCAL_IP#' $CURRENT_DIR/SALSA/salsa.engine.properties"
eval "sed -i 's#SALSA_CENTER_PORT=.*#SALSA_CENTER_PORT=8380#' $CURRENT_DIR/SALSA/salsa.engine.properties"
eval "sed -i 's#SALSA_CENTER_WORKING_DIR=.*#SALSA_CENTER_WORKING_DIR=$CURRENT_DIR/SALSA#' $CURRENT_DIR/SALSA/salsa.engine.properties"
eval "sed -i 's#SALSA_PIONEER_WORKING_DIR=.*#SALSA_PIONEER_WORKING_DIR=$CURRENT_DIR/SALSA/workspace#' $CURRENT_DIR/SALSA/salsa.engine.properties"
eval "sed -i 's#SALSA_REPO=.*#SALSA_REPO=http://$LOCAL_IP/iCOMOTTutorial/#' $CURRENT_DIR/SALSA/salsa.engine.properties"
eval "sed -i 's#CLOUD_USER_PARAMETERS=.*#CLOUD_USER_PARAMETERS=/etc/cloudUserParameters.ini#' $CURRENT_DIR/SALSA/salsa.engine.properties"

echo "Configuring SALSA service"
sudo -S cp ./SALSA/salsa-engine-service /etc/init.d/salsa-engine-service
sudo -S chmod +x /etc/init.d/salsa-engine-service
sudo -S update-rc.d salsa-engine-service defaults
 
#sudo -S service salsa-engine-service start

########## INSTALL GANGLIA ###########

echo "Checking if Ganglia exists"

if [[ -z $(which ganglia) ]]
  then
    echo "Installing Ganglia"
    sudo -S apt-get install ganglia-monitor gmetad -y
fi

echo "Configuring Ganglia"
wget  http://128.130.172.215/iCOMOTTutorial/files/Misc/GangliaCFG.tar.gz
tar -xzf ./GangliaCFG.tar.gz
rm ./GangliaCFG.tar.gz
sudo -S cp ./GangliaCFG/gmond.conf /etc/ganglia

sudo -S ifconfig lo:0 192.1.1.15

#sudo -S service ganglia-monitor restart

echo "Deploying MELA DataService"
echo "Downloading MELA DataService"
wget  http://128.130.172.215/iCOMOTTutorial/files/iCOMOTDistributedPlatform/mela-data-service.tar.gz
echo "Unpacking MELA DataService"
tar -xzf ./mela-data-service.tar.gz
rm ./mela-data-service.tar.gz

eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/mela-data-service/mela-data-service"
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/mela-data-service#' $CURRENT_DIR/mela-data-service/mela-data-service"

########## INSTALL MELA ###########

echo "Configuring MELA DataService service"
sudo -S cp ./mela-data-service/mela-data-service /etc/init.d/mela-data-service
sudo -S chmod +x /etc/init.d/mela-data-service
sudo -S update-rc.d mela-data-service defaults

#sudo -S service mela-data-service start

echo "Deploying MELA AnalysisService"
echo "Downloading MELA AnalysisService"
 
wget  http://128.130.172.215/iCOMOTTutorial/files/iCOMOTDistributedPlatform/mela-analysis-service.tar.gz
echo "Unpacking MELA AnalysisService"
tar -xzf ./mela-analysis-service.tar.gz
rm ./mela-analysis-service.tar.gz

eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/mela-analysis-service/mela-analysis-service"
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/mela-analysis-service#' $CURRENT_DIR/mela-analysis-service/mela-analysis-service"

echo "Configuring MELA AnalysisService service"
 
sudo -S cp ./mela-analysis-service/mela-analysis-service /etc/init.d/mela-analysis-service
sudo -S chmod +x /etc/init.d/mela-analysis-service
sudo -S update-rc.d mela-analysis-service defaults

#sudo service mela-analysis-service start
 
########## INSTALL rSYBL ###########
 
echo "Deploying rSYBL"
echo "Downloading rSYBL"
 
wget  http://128.130.172.215/iCOMOTTutorial/files/iCOMOTDistributedPlatform/rSYBL.tar.gz
echo "Unpacking rSYBL"
tar -xzf ./rSYBL.tar.gz
rm ./rSYBL.tar.gz

eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/rSYBL/rSYBL-service"
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/rSYBL#' $CURRENT_DIR/rSYBL/rSYBL-service"

echo "Configuring rSYBL service"
 
sudo -S cp ./rSYBL/rSYBL-service /etc/init.d/rSYBL-service
sudo -S chmod +x /etc/init.d/rSYBL-service
sudo -S update-rc.d rSYBL-service defaults

#sudo -S service rSYBL-service start

########## INSTALL rtGovOps ###########


########## INSTALL ELISE ###########

echo "Deploying ELISE"
echo "Downloading ELISE"

wget http://128.130.172.215/iCOMOTTutorial/files/iCOMOTDistributedPlatform/ELISE.tar.gz
tar -xzf ./ELISE.tar.gz
rm -rf ./ELISE.tar.gz

eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/ELISE/elise-service"
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/ELISE#' $CURRENT_DIR/ELISE/elise-service"

echo "Configuring ELISE service" 
sudo -S cp ./ELISE/elise-service /etc/init.d/elise-service
sudo -S chmod +x /etc/init.d/elise-service
sudo -S update-rc.d elise-service defaults
#sudo -S service elise-service start
#sudo cp ./ELISE/elise-client /usr/bin
#chmod +x /usr/bin/elise-client



########## INSTALL DashBoard ###########


echo "Deploying COMOT Dashboard"
echo "Downloading COMOT Dashboard"
 
wget  http://128.130.172.215/iCOMOTTutorial/files/iCOMOTDistributedPlatform/comot-dashboard-service.tar.gz
echo "Unpacking COMOT Dashboard"
tar -xzf ./comot-dashboard-service.tar.gz
rm ./comot-dashboard-service.tar.gz

eval "sed -i 's#HOST_IP#$HOST_IP#' $CURRENT_DIR/comot-dashboard-service/config/modules.xml"
eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/comot-dashboard-service/comot-dashboard-service"
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/comot-dashboard-service#' $CURRENT_DIR/comot-dashboard-service/comot-dashboard-service"

echo "Configuring COMOT Dashboard"
 
sudo -S cp ./comot-dashboard-service/comot-dashboard-service /etc/init.d/comot-dashboard-service
sudo -S chmod +x /etc/init.d/comot-dashboard-service
sudo -S update-rc.d comot-dashboard-service defaults


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
wget http://128.130.172.215/iCOMOTTutorial/files/iCOMOTDistributedPlatform/icomot-services
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
</html>' | sudo -S tee -a ./index.html

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
else 	

    declare -a ElasticIoTCloudPlatform_artifacts=(
        https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/artifacts/DaaS-1.0.tar.gz
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/artifacts/DaaSQueue-1.0.tar.gz
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/artifacts/ElasticCassandraSetup-1.0.tar.gz
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/artifacts/HAProxySetup-1.0.tar.gz
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/artifacts/LocalDataAnalysis.tar.gz
        https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/artifacts/apache-cassandra-1.2.6-bin.tar.gz
   )

   declare -a ElasticIoTCloudPlatform_Docker_scripts=(
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Docker/deployCassandraNode.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Docker/deployCassandraSeed.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Docker/deployEventProcessing.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Docker/deployLoadBalancer.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Docker/deployLocalAnalysis.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Docker/deployQueue.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Docker/deployWorkloadGenerator.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Docker/run_mqtt_broker.sh
   )

    declare -a ElasticIoTCloudPlatform_Flexiant_scripts=(
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployCassandraNode.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployCassandraSeed.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployEventProcessing.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployLoadBalancer.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployLocalAnalysis.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployQueue.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deploySensorUnit.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/deployWorkloadGenerator.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/Flexiant/run_mqtt_broker.sh
    )

    declare -a ElasticIoTCloudPlatform_OpenStack_scripts=(
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployCassandraNode.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployCassandraSeed.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployEventProcessing.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployLoadBalancer.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployLocalAnalysis.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployMoM.sh
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/OpenStack/deployQueue.shg
	https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/ElasticIoTCloudPlatform/scripts/OpenStack/run_mqtt_broker.sh

    )
 declare -a MISC_artifacts=(https://raw.githubusercontent.com/tuwiendsg/iCOMOT/devLocal/examples/Misc/artifacts/jre-7-linux-x64.tar.gz)


  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/artifacts
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/scripts
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/scripts/Docker
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/scripts/Flexiant
  sudo -S mkdir $REPOSITORY/ElasticIoTCloudPlatform/scripts/OpenStack
  sudo -S mkdir $REPOSITORY/Misc
  sudo -S mkdir $REPOSITORY/Misc/artifacts
  
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


  for i in "${MISC_artifacts[@]}"
  do
     sudo -S wget -q $i -P $REPOSITORY/Misc/artifacts/
  done

fi
echo -e "iCOMOT deployed. Please run: sudo service icomot-services start|stop " 
echo " "



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

########## INSTALL COMPACT iCOMOT ###########
echo "Deploying iCOMOT"
echo "Downloading iCOMOT"
wget  -q https://github.com/tuwiendsg/iCOMOT/blob/devLocal/bin/compact/iCOMOT-Platform.tar.gz?raw=true
echo "Unpacking iCOMOT"
tar -xzf ./iCOMOT-Platform.tar.gz
rm  ./iCOMOT-Platform.tar.gz

#download service's last version

sudo wget -q http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/mela/MELA-DataService/3.0-SNAPSHOT/MELA-DataService-3.0-SNAPSHOT.war  ./webapps/MELA.war
sudo wget -q http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/comot/COMOT-VisualizationService/0.0.1-SNAPSHOT/COMOT-VisualizationService-0.0.1-SNAPSHOT.war  ./webapps/iCOMOT.war
sudo wget -q http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/cloud/salsa/salsa-engine/1.0/salsa-engine-1.0.war  ./webapps/salsa-engine.war
sudo wget -q http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/mela/MELA-SpaceAndPathwayAnalysisService/3.0-SNAPSHOT/MELA-SpaceAndPathwayAnalysisService-3.0-SNAPSHOT.war  ./webapps1/MELA-AnalysisService.war

 
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/iCOMOT-Platform/#' $CURRENT_DIR/iCOMOT-Platform/icomot-platform"
eval "sed -i 's#JAVA_HOME=.*#JAVA_HOME=$CURRENT_DIR/jre1.7.0/#' $CURRENT_DIR/iCOMOT-Platform/icomot-platform"

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

eval "sed -i 's#SALSA_CENTER_IP=.*#SALSA_CENTER_IP$LOCAL_IP#' $CURRENT_DIR/iCOMOT-Platform/salsa.engine.properties"

eval "sed -i 's#SALSA_CENTER_WORKING_DIR=.*#SALSA_CENTER_WORKING_DIR=$CURRENT_DIR/salsa-engine#' $CURRENT_DIR/iCOMOT-Platform/salsa.engine.properties"
 
mkdir $CURRENT_DIR/salsa-engine/

chmod 0777 $CURRENT_DIR/salsa-engine/

eval "sed -i 's#HOST_IP#$HOST_IP#' $CURRENT_DIR/iCOMOT-Platform/config/modules.xml"
 
sudo -S chmod +x ./iCOMOT-Platform/icomot-platform
sudo -S cp ./iCOMOT-Platform/icomot-platform /etc/init.d/icomot-platform
sudo -S chmod +x /etc/init.d/icomot-platform
sudo -S update-rc.d icomot-platform defaults

sudo -S service icomot-platform start 

cd ./iCOMOT-Platform
CURRENT_DIR=$(pwd)


wget -q https://github.com/tuwiendsg/iCOMOT/blob/devLocal/bin/compact/iCOMOT-Platform.tar.gz?raw=true
tar -xzf ./rSYBL.tar.gz
rm ./rSYBL.tar.gz

eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/rSYBL/rSYBL-service"
eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/rSYBL#' $CURRENT_DIR/rSYBL/rSYBL-service"

sudo -S cp ./rSYBL/rSYBL-service /etc/init.d/rSYBL-service
sudo -S chmod +x /etc/init.d/rSYBL-service
sudo -S update-rc.d rSYBL-service defaults

sudo -S service rSYBL-service start


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
wget http://128.130.172.215/iCOMOTTutorial/files/iCOMOTCompactPlatform/icomot-services
sudo -S cp icomot-services /etc/init.d/icomot-services
sudo -S chmod +x /etc/init.d/icomot-services
sudo -S update-rc.d icomot-services defaults

echo -e "iCOMOT deployed. Please run: sudo service icomot-services start|stop " 
echo " "



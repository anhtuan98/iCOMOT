# This script for installing iCOMOT
#!/bin/bash

# firstly install dialog
if which dialog > /dev/null; then
  echo "Running installation..."
else
  echo "The installation require \"dialog\" to run. Trying to install it now."
  sudo apt-get update
  sudo apt-get -y install dialog
fi


CURRENT_DIR=`pwd`
CONFIG_INFO=$CURRENT_DIR/icomotInstallation.info

TMPDLG=$CURRENT_DIR/install.tmp
dialog --title "iCOMOT platform installation" \
--checklist "Please select the services you want to install.\nSelect by up/down, On/off selection by Space. Confirm by Enter." 18 75 8 \
                   "Dashboard"  "iCOMOT Dashboard" on \
                   "SALSA"      "Deployment and Configuration" on \
                   "MELA"       "Monitoring and Analysis" on \
                   "rSYBL"      "Elasticity control" on \
                   "rtGovOps"   "IoT Governance" on \
                   "ELISE"      "Elasticity Information Service" on \
                   "Repository" "iCOMOT artifact repository" off \
                   "docker"     "For deploying application on this machine" off 2> $TMPDLG
                   
STATUS_PENDING="pending"
STATUS_SKIPPED="skipped"
STATUS_DONE="done"

Dashboard=$STATUS_PENDING
SALSA=$STATUS_PENDING
MELA=$STATUS_PENDING
rSYBL=$STATUS_PENDING
rtGovOps=$STATUS_PENDING
ELISE=$STATUS_PENDING
repo=$STATUS_PENDING
docker=$STATUS_PENDING

INSTALL_OPT=`cat $TMPDLG`


dialog --inputbox "Where do you want to install iCOMOT:" 18 75 "./iCOMOTWorkspace" 2> $TMPDLG
INSTALL_DIR=`cat $TMPDLG`
if [ -z "$INSTALL_DIR" ]; then echo "Installation canceled"; exit 1; fi

if [[ $INSTALL_OPT =~ .*Dashboard.* ]]; then
  dialog --inputbox "Please enter the accessible IP for the Dashboard if available.\nLeave empty to use \"localhost\"." 18 75 2> $TMPDLG
  HOST_IP=$(cat $TMPDLG | tr -d ' ')
  if [ -z "$HOST_IP" ]; then
    HOST_IP=localhost
  fi
fi


echo ""
echo "#############################################################"
echo ""

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

CURRENT_DIR=$(pwd)

JAVA=$(which java)

function install_jre(){
  echo "Installing JRE..."
  if [[ -z $JAVA ]]
    then
        echo "Downloading jre"
        wget --progress=dot:mega --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jre-8u45-linux-x64.tar.gz
        echo "Unpacking JRE"
        tar -xzf ./jre-8u45-linux-x64.tar.gz 
        rm  ./jre-8u45-linux-x64.tar.gz
        JAVA=$CURRENT_DIR/jre1.8.0_45/bin/java
        eval "sed -i 's#securerandom.source=.*#securerandom.source=file:/dev/./urandom#' $CURRENT_DIR/jre1.8.0_45/lib/security/java.security"
  fi
}

########## INSTALL SALSA ###########
function install_SALSA(){
  echo "Installing SALSA..."
  

  wget --progress=dot:mega https://github.com/tuwiendsg/iCOMOT/blob/master/bin/resources/SALSA.tar.gz?raw=true -O ./SALSA.tar.gz
  echo "Unpacking SALSA"
  tar -xzf ./SALSA.tar.gz
  rm  ./SALSA.tar.gz

  sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/cloud/salsa/salsa-engine/1.0/salsa-engine-1.0-exec-war.jar -O  ./SALSA/salsa-engine.jar
  sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/dsg/cloud/salsa/salsa-pioneer-vm/1.0/salsa-pioneer-vm-1.0.jar -O  ./SALSA/salsa-pioneer.jar

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
}

########## INSTALL GANGLIA ###########
function install_Ganglia(){
    echo "Checking if Ganglia exists"
    
    if [[ -z $(which ganglia) ]]
      then
        echo "Installing Ganglia"
        sudo -S apt-get install ganglia-monitor gmetad -y
    fi

    echo "Configuring Ganglia"
    wget https://github.com/tuwiendsg/iCOMOT/raw/master/bin/resources/GangliaCFG.tar.gz
    tar -xzf ./GangliaCFG.tar.gz
    rm ./GangliaCFG.tar.gz
    sudo -S cp ./GangliaCFG/gmond.conf /etc/ganglia

    sudo -S ifconfig lo:0 192.1.1.15
}

########## INSTALL MELA ###########
function install_MELA(){
    echo "Installing MELA DataService"
    echo "Downloading MELA DataService artifact"
    wget https://github.com/tuwiendsg/iCOMOT/blob/master/bin/resources/mela-data-service.tar.gz?raw=true -O ./mela-data-service.tar.gz
    echo "Unpacking MELA DataService"
    tar -xzf ./mela-data-service.tar.gz
    rm ./mela-data-service.tar.gz

    sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/mela/MELA-DataService/3.0-SNAPSHOT/MELA-DataService-3.0-SNAPSHOT-exec-war.jar -O ./mela-data-service/MELA-DataService-3.0-SNAPSHOT-war-exec.jar

    eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/mela-data-service/mela-data-service"
    eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/mela-data-service#' $CURRENT_DIR/mela-data-service/mela-data-service"

    echo "Configuring MELA DataService service"
    sudo -S cp ./mela-data-service/mela-data-service /etc/init.d/mela-data-service
    sudo -S chmod +x /etc/init.d/mela-data-service
    sudo -S update-rc.d mela-data-service defaults


    echo "Deploying MELA AnalysisService"
    echo "Downloading MELA AnalysisService"
    wget https://github.com/tuwiendsg/iCOMOT/blob/master/bin/resources/mela-analysis-service.tar.gz?raw=true -O ./mela-analysis-service.tar.gz
    echo "Unpacking MELA AnalysisService"
    tar -xzf ./mela-analysis-service.tar.gz
    rm ./mela-analysis-service.tar.gz

    sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/mela/MELA-SpaceAndPathwayAnalysisService/3.0-SNAPSHOT/MELA-SpaceAndPathwayAnalysisService-3.0-SNAPSHOT-exec-war.jar -O ./mela-analysis-service/MELA-SpaceAndPathwayAnalysisService-3.0-SNAPSHOT-war-exec.jar

    eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/mela-analysis-service/mela-analysis-service"
    eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/mela-analysis-service#' $CURRENT_DIR/mela-analysis-service/mela-analysis-service"

    echo "Configuring MELA AnalysisService service"
     
    sudo -S cp ./mela-analysis-service/mela-analysis-service /etc/init.d/mela-analysis-service
    sudo -S chmod +x /etc/init.d/mela-analysis-service
    sudo -S update-rc.d mela-analysis-service defaults
}

 ########## INSTALL rSYBL ###########
function install_rSYBL(){
    wget  https://github.com/tuwiendsg/iCOMOT/blob/master/bin/resources/rSYBL.tar.gz?raw=true -O ./rSYBL.tar.gz
    tar -xzf ./rSYBL.tar.gz
    rm ./rSYBL.tar.gz

    sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/comot/at/ac/tuwien/rSYBL/control-service/rSYBL-analysis-engine/1.0-SNAPSHOT/rSYBL-analysis-engine-1.0-SNAPSHOT-exec-war.jar -O  ./rSYBL/rSYBL-analysis-engine-1.0-SNAPSHOT-war-exec.jar

    eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/rSYBL/rSYBL-service"
    eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/rSYBL#' $CURRENT_DIR/rSYBL/rSYBL-service"

    sudo -S cp ./rSYBL/rSYBL-service /etc/init.d/rSYBL-service
    sudo -S chmod +x /etc/init.d/rSYBL-service
    sudo -S update-rc.d rSYBL-service defaults
    #sudo -S service rSYBL-service start
}

########## INSTALL rtGovOps ###########

function install_rtGovOps(){
  wget https://github.com/tuwiendsg/iCOMOT/blob/master/bin/resources/GovOps.tar.gz?raw=true -O ./GovOps.tar.gz
  tar -xzf ./GovOps.tar.gz
  rm ./GovOps.tar.gz

  echo "Downloading jre"
  #wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jre-8u45-linux-x64.tar.gz
  #echo "Unpacking JRE"
  #tar -xzf ./jre-8u45-linux-x64.tar.gz 
  #rm  ./jre-8u45-linux-x64.tar.gz

  sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/apimanager/1.0-SNAPSHOT/apimanager-1.0-SNAPSHOT.war -O ./GovOps/webapps/APIManager.war
  sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGManager/1.0-SNAPSHOT/SDGManager-1.0-SNAPSHOT.war -O ./GovOps/webapps/SDGManager.war
  sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGBalancer/1.0-SNAPSHOT/SDGBalancer-1.0-SNAPSHOT.war -O ./GovOps/webapps/SDGBalancer.war
  sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGBuilder/1.0-SNAPSHOT/SDGBuilder-1.0-SNAPSHOT.war -O ./GovOps/webapps/SDGBuilder.war
  sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/common/1.0-SNAPSHOT/common-1.0-SNAPSHOT.jar -O  ./GovOps/webapps/common-1.0-SNAPSHOT.jar

  eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/GovOps/#' $CURRENT_DIR/GovOps/govops-service"
  #eval "sed -i 's#JAVA_HOME=.*#JAVA_HOME=$CURRENT_DIR/jre1.7.0/#' $CURRENT_DIR/iCOMOT-Platform/icomot-platform"
  eval "sed -i 's#JAVA_HOME=.*#JAVA_HOME=$CURRENT_DIR/jre1.8.0_45/#' $CURRENT_DIR/GovOps/govops-service"

  sudo -S chmod +x ./GovOps/govops-service
  sudo -S cp ./GovOps/govops-service /etc/init.d/govops-service
  sudo -S chmod +x /etc/init.d/govops-service
  sudo -S update-rc.d govops-service defaults
}

########## INSTALL ELISE ###########
function install_ELISE(){
    echo "Deploying ELISE"
    echo "Downloading ELISE"
    wget https://github.com/tuwiendsg/iCOMOT/blob/master/bin/resources/ELISE.tar.gz?raw=true -O ./ELISE.tar.gz
    tar -xzf ./ELISE.tar.gz
    rm -rf ./ELISE.tar.gz

    wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/dsg/comot/elise/elise-service/1.0/elise-service-1.0-war-exec.jar -O ./ELISE/elise-service-1.0-war-exec.jar
    wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/dsg/comot/elise/elise-collector-salsa/1.0/elise-collector-salsa-1.0.jar -O ./ELISE/extensions/salsa/elise-collector-salsa-1.0.jar
    wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/dsg/comot/elise/elise-collector-govops/1.0/elise-collector-govops-1.0.jar -O ./ELISE/extensions/govops/elise-collector-govops-1.0.jar

    eval "sed -i 's#JAVA=.*#JAVA=$JAVA#' $CURRENT_DIR/ELISE/elise-service"
    eval "sed -i 's#DAEMONDIR=.*#DAEMONDIR=$CURRENT_DIR/ELISE#' $CURRENT_DIR/ELISE/elise-service"

    echo "Configuring ELISE service" 
    sudo -S cp ./ELISE/elise-service /etc/init.d/elise-service
    sudo -S chmod +x /etc/init.d/elise-service
    sudo -S update-rc.d elise-service defaults
}


########## INSTALL DashBoard ###########
function install_Dashboard(){
    echo "Deploying COMOT Dashboard"
    echo "Downloading COMOT Dashboard"
    
 
         
    wget  https://github.com/tuwiendsg/iCOMOT/blob/master/bin/resources/comot-dashboard-service.tar.gz?raw=true -O ./comot-dashboard-service.tar.gz

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
}

########## INSTALL DOCKER ###########
function install_docker() {
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

######### INSTALL icomot-service script ##########
function install_icomot_script(){
    wget https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/bin/distributed/icomot-services
    sudo -S cp icomot-services /etc/init.d/icomot-services
    sudo -S chmod +x /etc/init.d/icomot-services
    sudo -S update-rc.d icomot-services defaults
}


######### INSTALL icomot-service oftware repository ##########
function install_repo(){ 
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
} # end install_repo



if [[ $INSTALL_OPT =~ .*Dashboard.* ]]; then  
  install_Dashboard
  Dashboard=$STATUS_DONE
else
  Dashboard=$STATUS_SKIPPED
fi

if [[ $INSTALL_OPT =~ .*SALSA.* ]]; then
  install_SALSA
  SALSA=$STATUS_DONE
else
  SALSA=$STATUS_SKIPPED
fi

if [[ $INSTALL_OPT =~ .*MELA.* ]]; then
  install_MELA
  MELA=$STATUS_DONE
else
  MELA=$STATUS_SKIPPED
fi

if [[ $INSTALL_OPT =~ .*rSYBL.* ]]; then
  install_rSYBL
  rSYBL=$STATUS_DONE
else
  rSYBL=$STATUS_SKIPPED
fi

if [[ $INSTALL_OPT =~ .*ELISE.* ]]; then
  install_ELISE
  ELISE=$STATUS_DONE
else
  ELISE=$STATUS_SKIPPED
fi

if [[ $INSTALL_OPT =~ .*rtGovOps.* ]]; then
  cp ../installGovOps.sh .
  sudo bash ./installGovOps.sh
  rtGovOps=$STATUS_DONE
  rm ./installGovOps.sh
else
  rtGovOps=$STATUS_SKIPPED
fi

if [[ $INSTALL_OPT =~ .*Repository.* ]]; then
  install_repo
  repo=$STATUS_DONE
else
  repo=$STATUS_SKIPPED
fi

if [[ $INSTALL_OPT =~ .*docker.* ]]; then
  #install_docker
  runInstallation install_docker
  docker=$STATUS_DONE
else
  docker=$STATUS_SKIPPED
fi

install_icomot_script

echo "INSTALL_DIR=$INSTALL_DIR" >  $CONFIG_INFO
echo "INSTALL_OPT=\"$INSTALL_OPT\"" >> $CONFIG_INFO

rm $TMPDLG

echo -e "\n\nInstallation complete. Status: \n$INFO"
echo -e "SALSA     :$SALSA\nMELA      :$MELA\nrSYBL     :$rSYBL\nrtGovOps  :$rtGovOps\nELISE     :$ELISE\nDashboard :$Dashboard\ndocker    :$docker\nRepository:$repo"

echo -e "\n \niCOMOT deployed. Please run: sudo service icomot-services start|stop " 
echo " "



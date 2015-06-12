#!/bin/sh

INFO="./icomotInstallation.info"
if [ -f $INFO ]; then
  . $INFO
  sudo rm $INFO
else
  echo "Installation information does not found. This will try to uninstall all possible iCOMOT service."
  PS3='Please enter your choice: '
  select opt in "Uninstall all iCOMOT services" "Abort"
  do
    case $opt in
        "Uninstall all iCOMOT services")
        INSTALL_DIR=./iCOMOTWorkspace
        INSTALL_OPT="Dashboard SALSA MELA rSYBL ELISE rtGovOps"
        break
        ;;
      "Abort")
        exit 0
        ;;
      *) exit 1;;
    
    esac
  done  
fi

echo $INSTALL_DIR
echo $INSTALL_OPT


if [[ $INSTALL_OPT =~ .*MELA.* ]]; then
  echo "Removing mela-analysis-service"
  sudo -S service mela-analysis-service stop
  sudo -S rm /etc/init.d/mela-analysis-service
  sudo -S update-rc.d -f mela-analysis-service remove

  echo "Removing mela-analysis-service"
  sudo -S service mela-cost-service stop
  sudo -S rm /etc/init.d/mela-cost-service
  sudo -S update-rc.d -f mela-cost-service remove

  echo "Removing mela-data-service"
  sudo -S service mela-data-service stop
  sudo -S rm /etc/init.d/mela-data-service
  sudo -S update-rc.d -f mela-data-service remove
fi

if [[ $INSTALL_OPT =~ .*rSYBL.* ]]; then
  echo "Removing rSYBL-service"
  sudo -S service rSYBL-service stop
  sudo -S rm /etc/init.d/rSYBL-service
  sudo -S update-rc.d -f rSYBL-service remove
  sudo -S rm -rf ./rSYBL  
fi

if [[ $INSTALL_OPT =~ .*SALSA.* ]]; then
  echo "Removing salsa-engine"
  sudo -S service salsa-engine-service stop
  sudo -S rm /etc/init.d/salsa-engine-service 
  sudo -S update-rc.d salsa-engine-service remove  
  sudo -S rm -rf ./SALSA  
fi

if [[ $INSTALL_OPT =~ .*ELISE.* ]]; then
echo "Removing elise-engine"
sudo -S service elise-service stop
sudo -S rm /etc/init.d/elise-service 
sudo -S update-rc.d elise-service remove  
sudo -S rm -rf ./ELISE  
sudo -S rm -f /usr/bin/elise-client
fi

if [[ $INSTALL_OPT =~ .*Dashboard.* ]]; then 
echo "Removing comot-dashboard-service"
sudo -S service comot-dashboard-service stop
sudo -S rm /etc/init.d/comot-dashboard-service
sudo -S update-rc.d -f comot-dashboard-service remove
sudo -S rm -rf ./comot-*
fi


if [[ $INSTALL_OPT =~ .*repo.* ]]; then
  REPOSITORY=/var/www/html/iCOMOTTutorial/
  sudo -S rm -rf $REPOSITORY
  sudo -S apt-get remove apache2 php5 -y
  sudo -S ifconfig lo:0 down
fi

if [[ $INSTALL_OPT =~ .*docker.* ]]; then
  sudo docker kill $(docker ps -q)
  sudo docker rm $(docker ps -a -q)
  sudo docker rmi $(docker images -q -f dangling=true)
  sudo docker rmi $(docker images -q)
  sudo apt-get -y erase lxc-docker
fi


echo "Removing ganglia"
sudo -S apt-get remove ganglia-monitor gmetad -y

echo "Remove iCOMOT service script"
sudo -S rm /etc/init.d/icomot-services
sudo -S update-rc.d -f icomot-services remove

sudo -S rm -rf $INSTALL_DIR

echo "Completly removing: $INSTALL_OPT"


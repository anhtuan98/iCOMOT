# firstly install dialog
if which java > /dev/null; then
  echo "Running installation..."
else
  echo "The installation require \"dialog\" to run. Trying to install it now."
  sudo apt-get update
  sudo apt-get -y install dialog
fi

TMPDLG=./install.tmp
dialog --colors --title "iCOMOT platform installation" \
--menu "Please select iCOMOT configurations.\n\n\ZbCompact configuration:\Zn\n - All services (except rSYBL) are deployed in the same web container.\n - Significantly less memory usage, but at somewhat reduced performance.\n - Minimum 3GB RAM, Recommended 4GB.\n\n\ZbDistributed configuration:\Zn\n - Each service runs isolated in its own web container.\n - Provides high performance, but at high memory usage.\n - Minimum 4GB RAM, Recommended 6GB." 22 80 2 \
                   "Compact"          "Less memory usage, less performance" \
                   "Distributed"      "High memory usage, higher performance" 2> $TMPDLG
OPTION=`cat $TMPDLG`
rm $TMPDLG

case $OPTION  in
  Compact)       
    cd compact
    bash installCOMOT.sh
    ;;
  Distributed)
    cd distributed
    bash installCOMOT.sh
    ;;                          
 *) echo "Installation is cancelled"; exit 0;;
esac 
                   
                   


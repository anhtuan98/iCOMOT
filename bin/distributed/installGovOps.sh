#### Install Oracle Java 8 ##########
echo "\r\n" | sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
echo Y | sudo apt-get install oracle-java8-installer

#### Install Tomcat ##########
echo yes | sudo apt-get update
echo Y | sudo apt-get install tomcat7
sudo bash -c 'echo JAVA_HOME=/usr/lib/jvm/java-8-oracle >> /etc/default/tomcat7'
sudo service tomcat7 restart

#### Install GovOps ##########
sudo service tomcat7 stop

sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/apimanager/1.0-SNAPSHOT/apimanager-1.0-SNAPSHOT.war -O ./APIManager.war
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGManager/1.0-SNAPSHOT/SDGManager-1.0-SNAPSHOT.war -O ./SDGManager.war
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGBalancer/1.0-SNAPSHOT/SDGBalancer-1.0-SNAPSHOT.war -O ./SDGBalancer.war
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/SDGBuilder/1.0-SNAPSHOT/SDGBuilder-1.0-SNAPSHOT.war -O ./SDGBuilder.war
sudo -S wget http://repo.infosys.tuwien.ac.at/artifactory/simple/dev/at/ac/tuwien/infosys/common/1.0-SNAPSHOT/common-1.0-SNAPSHOT.jar -O  ./common-1.0-SNAPSHOT.jar

sudo cp *.war *.jar /var/lib/tomcat7/webapps/
sudo rm -rf  APIManager.war
sudo rm -rf  SDGManager.war
sudo rm -rf  SDGBuilder.war
sudo rm -rf  SDGBalancer.war
sudo rm -rf  common-1.0-SNAPSHOT.jar
sudo service tomcat7 start

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
wget http://128.130.172.215/salsa/upload/files/rtGovOps/install/APIManager.war
wget http://128.130.172.215/salsa/upload/files/rtGovOps/install/SDGManager.war
wget http://128.130.172.215/salsa/upload/files/rtGovOps/install/SDGBalancer.war
wget http://128.130.172.215/salsa/upload/files/rtGovOps/install/SDGBuilder.war
wget http://128.130.172.215/salsa/upload/files/rtGovOps/install/common-1.0-SNAPSHOT.jar
sudo cp *.war *.jar /var/lib/tomcat7/webapps/
sudo rm -rf  APIManager.war
sudo rm -rf  SDGManager.war
sudo rm -rf  SDGBuilder.war
sudo rm -rf  SDGBalancer.war
sudo rm -rf  common-1.0-SNAPSHOT.jar
sudo service tomcat7 start
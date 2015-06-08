#/bin/bash

COL=2
NAME=ch3_cktA_suction_pressure
DATASET=low_suction_pressure_ch3

wget -qN http://128.130.172.215/salsa/upload/files/DaasService/IoT/non-chef-sensor.tar.gz
tar -xzkf non-chef-sensor.tar.gz

cd non-chef-sensor
wget -qN http://128.130.172.215/salsa/upload/files/DaasService/IoT/data/chiller/$DATASET.csv

echo "id,sensorName,sensorValue" > config-files/data.csv
cat $DATASET.csv | sed 1d > $DATASET.csv.tmp
awk -F',' '{print "'$DATASET','$NAME',"$'$COL'}' $DATASET.csv.tmp >> config-files/data.csv
rm $DATASET.csv.tmp

java -cp 'bootstrap_container-0.0.1-SNAPSHOT-jar-with-dependencies.jar:*' container.Main

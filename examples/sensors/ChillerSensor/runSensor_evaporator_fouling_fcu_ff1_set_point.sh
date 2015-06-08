#/bin/bash

COL=3
NAME=fcu_ff1_set_point
DATASET=evaporator_fouling

echo "id,sensorName,sensorValue" > config-files/data.csv
cat $DATASET.csv | sed 1d > $DATASET.csv.tmp
awk -F',' '{print "'$DATASET','$NAME',"$'$COL'}' $DATASET.csv.tmp >> config-files/data.csv
rm $DATASET.csv.tmp

java -cp 'bootstrap_container-0.0.1-SNAPSHOT-jar-with-dependencies.jar:*' container.Main

#/bin/bash

mv -f data_gps.csv config-files/data.csv
java -cp 'bootstrap_container-0.0.1-SNAPSHOT-jar-with-dependencies.jar:*' container.Main

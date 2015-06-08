#!/bin/bash
# This simple script gets parameters, wraps them into JSON and send the request to ELISE service
# User can edit the default parameter, e.g. ELISE endpoint
# Usage:
# elise-client.sh <category> [rules]

IP=localhost
PORT=8580
REST=http://$IP:$PORT/elise-service/rest


if [ $# -lt 1 ]
then
        echo "Usage : $0 <category> [rule...]"
        echo "  "
        echo "   <category>    = SENSOR|GATEWAY|VM"
        echo "   [rule...]     = metric:OPERATION:value "
        echo " "
        echo "Multiple rules can be used to filter service instances based on instance's properties. A rule consists of:"
        echo "   metric        : Name of the properties. The common way is query instance based on its metadata"
        echo "                   e.g serviceID, IP. If ELISE is able to collect other metrics, they can be used in rules"
        echo "   OPERATION     : EQUAL | GREATER | LESSER | GREATER_OR_EQUAL | LESSER_OR_EQUAL"
        echo "   value         : Value of the metric need to be fulfilled"
        echo " "
        exit 1
fi

if [ "$1" == "SENSOR" ]
then
  category="DEVICE"
elif [ "$1" == "GATEWAY" ]
then
  category="DOCKER"
elif [ "$1" == "VM" ]
then 
  category="VirtualMachine"
else
  category="SOFTWARE"
fi


# build the query: {"category":"DEVICE","rules":[{"metric":"test","value":"value","operation":"EQUAL"}],"hasCapabilities":[]}
QUERY='{"category":"'$category'","rules":['

shift

atLeastOne=0
while test ${#} -gt 0
do
  rule=$1
  arr=(${rule//:/ })
 ## if it is the first rule, add a branket {
  if [ $atLeastOne -eq 0 ]; then
     QUERY=$QUERY'{'
     atLeastOne=1
  fi
  QUERY=$QUERY'"metric":"'${arr[0]}'","value":"'${arr[2]}'","operation":"'${arr[1]}'",'
  shift
done
# remove the last comma if there is at least one rule, add a closed branket }
if [ $atLeastOne -eq 1 ]; then
	QUERY=${QUERY%?}'}'
fi
QUERY=$QUERY'],"hasCapabilities":[]}'

QueryUUID=$(curl \
	 -H "Content-Type: application/json" \
	 -H "Accept: application/json" \
	 -X POST \
	 -d "$QUERY" \
	 $REST/communication/queryUnitInstance )

### Show the status ###

spin='-\|/'
i=0
count=0

while [[ -z "$keypress" ]]; do
  i=$(( (i+1) %4 ))
  clear
  echo "ELISE is collecting information ... ${spin:$i:1}"
  echo " "
  echo "Query: $QUERY"
  echo "Query UUID: $QueryUUID"
  echo "Status of the query:"
  echo " "
  progress=$(curl -sb  \
         -H "Content-Type: application/json" \
         -H "Accept: application/json" \
         -X GET \
         $REST/manager/query/$QueryUUID )
  progress=`echo $progress | tr -d '{' | tr -d '}' | tr "," "\n"`
  echo -e "$progress"
  echo " "
  echo -e "Press a key to get the result (not spacebar/return/specials)..."
  read -d'' -s -t2 -n1 keypress
done

### Show the result ####
result=$(curl  \
         -H "Content-Type: application/json" \
         -H "Accept: application/json" \
         -X POST \
	 -d "$QUERY" \
         $REST/unitinstance/queryDB)
echo " "
echo $result

#echo $RESULT | python -m json.tool

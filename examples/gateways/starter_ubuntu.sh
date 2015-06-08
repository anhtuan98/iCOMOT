#!/bin/sh

#i="0"
#while [ $i -lt 120 ]
#do
#	echo Running in container X-$i at time `date` >> /root/cron_log 2>&1
#	let i=i+1
#	sleep 1
#done

echo "SALSA_ENV_PORTMAP_80=$SALSA_ENV_PORTMAP_80" >> /etc/environment
echo "SALSA_ENV_PORTMAP_2812=$SALSA_ENV_PORTMAP_2812" >> /etc/environment
echo "SALSA_ENV_PORTMAP_5683=$SALSA_ENV_PORTMAP_5683" >> /etc/environment

#add capability for automatically deregistering from govOps - commented out: added in Dockerfile
# wget http://128.130.172.215/salsa/upload/files/rtGovOps/decommission

sudo -S cp ./decommission /bin/decommission
sudo -S chmod +x /bin/decommission

#end add capability

/usr/bin/gcc /usr/lib/cgi-bin/capabilities/elevate.c -o /usr/lib/cgi-bin/capabilities/elevate


# Start Apache on Ubuntu
/usr/sbin/a2enmod cgi
/usr/sbin/apache2ctl start

chown www-data /bin/kill

#Run the agent only once to register with rtGovOps server
/bin/bash -c "/usr/share/provi-agent/agent.sh"

#/bin/sh -c crond start && tail -F /usr/share/provi-agent/cron_log
tail -F /usr/share/provi-agent/cron_log

exit 0

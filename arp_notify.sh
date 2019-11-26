#!/bin/bash
#
# Stores data in memory but writes it to flash daily via backup script
#
# If there are "trusted" devices you wish to ignore, put the MAC address, or
# their whole ARP table entry into a file called .arpignore
#
# If there are devices that need to trigger webhooks, then create a
# .arpnotify file with this format for arriving:
# + MAC URL
# or this format for leaving:
# - MAC URL
#
# To install: 
# mkdir -p /config/arp_notify
# cp backup.sh arp_notify.sh /config/arp_notify
# crontab -e
# 23 11 * * * /config/arp_notify/backup.sh
# */5 * * * * /config/arp_notify/arp_notify.sh
#
# optional if you want to be notified via pushover if devices arrive/leave
pushover_user_token=""
pushover_app_token=""
# if you're not using pushover, uncomment the line below.
#logonly=1
# These are specific to EdgeOS
arpcommand="/opt/vyatta/bin/vyatta-op-cmd-wrapper show arp"
dhcpleases="/opt/vyatta/bin/vyatta-op-cmd-wrapper show dhcp leases"
hostname=`hostname`
service="ARP Monitor"
dir="/var/log/arp_notify"

if [ ! -d $dir ]
then
    cp -Rp /config/arp_notify $dir
fi

if [ ! -f $dir/.arptable ]
then
    touch $dir/.arptable
fi
$arpcommand | grep -v 'incomplete' > $dir/.arptablenew
touch $dir/.arplist
echo "New ARP Entries" > $dir/.arplist
count=1
for newarp in $(diff $dir/.arptable $dir/.arptablenew | grep + | grep ether | sed 's/^+//g' | awk '{print $1}')
do
    if [ count -eq 1 ]
    then
	$dhcpleases > $dir/.dhcpleases
 	count=`expr $count + 1`
    fi

    if [ -f $dir/.arpnotify ]
    then
	new_mac=`grep "$newarp" $dir/.dhcpleases |  awk '{print $2}'`
	for notify in $(grep "$new_mac" $dir/.arpnotify | grep -v "^#" | grep + | awk '{print $3}')
	do
		logger -t [arp_notify] "New Device Detected ($new_mac) -> Notifying $notify"
		curl -s "$notify"
	done
    fi

    if [ -f $dir/.arpignore ]
    then
    	if [[ $(grep -L "$newarp" $dir/.arpignore) ]]; then
		new_entry="$newarp - $(grep "$newarp" $dir/.dhcpleases | awk '{print $6}')"
    		logger -t [arp_notify] "New Device Detected -> $new_entry"
    		echo $new_entry >> $dir/.arplist
    	fi
    else
	new_entry="$newarp - $(grep "$newarp" $dir/.dhcpleases | awk '{print $6}')"
    	logger -t [arp_notify] "New Device Detected -> $new_entry"
    	echo $new_entry >> $dir/.arplist
    fi
done

echo "" >> $dir/.arplist
echo "Removed ARP Entries" >> $dir/.arplist
count=1
for noarp in $(diff $dir/.arptable $dir/.arptablenew | grep - | grep ether | sed 's/^-//g' | awk '{print $1}')
do
    if [ count -eq 1 ]
    then
	$dhcpleases > $dir/.dhcpleases
 	count=`expr $count + 1`
    fi

    if [ -f $dir/.arpnotify ]
    then
	lost_mac=`grep "$noarp" $dir/.dhcpleases | awk '{print $2}'`
	for notify in $(grep "$lost_mac" $dir/.arpnotify | grep -v "^#" | grep - | awk '{print $3}')
	do
		logger -t [arp_notify] "ARP Entry Removed ($lost_mac) -> Notifying $notify"
		curl -s "$notify"
	done
    fi
    if [ -f $dir/.arpignore ]
    then
    	if [[ $(grep -L "$noarp" $dir/.arpignore) ]]; then
    		lost_entry="$noarp - $(grep "$noarp" $dir/.dhcpleases | awk '{print $6}')"
    		logger -t [arp_notify] "ARP Entry Removed -> $lost_entry"
    		echo $lost_entry >> $dir/.arplist
    	fi
    else
    	lost_entry="$noarp - $(grep "$noarp" $dir/.dhcpleases | awk '{print $6}')"
    	logger -t [arp_notify] "ARP Entry Removed -> $lost_entry"
    	echo $lost_entry >> $dir/.arplist
    fi
done

message=$(cat $dir/.arplist)
if [ $(md5sum $dir/.arplist | awk '{ print $1 }') == "308be3015f740a9ad40a062a8738fba7" ]
then
    logger -t [arp_notify] "No new ARP entries detected."
else
    if [ -z $logonly ]
    then
        logger -t [arp_notify] "ARP table changes were detected. Sending alert."
		curl -s --form-string "token=$pushover_app_token" \
				--form-string "user=$pushover_user_token" \
				--form-string "message=[$hostname] $service - $message" \
				https://api.pushover.net/1/messages.jsonop
    else
        logger -t [arp_notify] "ARP table changes were detected."
    fi
fi

rm $dir/.arplist $dir/.arptable
if [ -f $dir/.dhcpleases ]
then
    rm $dir/.dhcpleases
fi
mv $dir/.arptablenew $dir/.arptable

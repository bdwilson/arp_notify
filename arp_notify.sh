#!/bin/bash
#
# Stores data in memory but writes it to flash daily via backup script
#
# If there are "trusted" devices you wish to ignore, put the MAC address, or
# their whole ARP table entry into a file called .arpignore
#
# To install: 
# mkdir -p /config/arp_notify
# cp backup.sh arp_notify.sh /config/arp_notify
# crontab -e
# 23 11 * * * /config/arp_notify/backup.sh
# */5 * * * * /config/arp_notify/arp_notify.sh
#
arpcommand="/opt/vyatta/bin/vyatta-op-cmd-wrapper show arp"
pushover_user_token="<pushover_user_token>"
pushover_app_token="<pushover_app_token"
hostname=`hostname`
service="ARP Monitor"
logonly=1  # comment this out to send pushover events.
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
for newarp in $(diff $dir/.arptable $dir/.arptablenew | grep + | grep ether | sed 's/^+//g' | awk '{print $1}')
do
    if [ -f $dir/.arpignore ]
    then
    	if [[ $(grep -L "$newarp" $dir/.arpignore) ]]; then
		new_entry="$newarp - $(/opt/vyatta/bin/vyatta-op-cmd-wrapper show dhcp leases | grep "$newarp" | awk '{print $6}')"
    		logger -t [arp_notify] "New Device Detected -> $new_entry"
    		echo $new_entry >> $dir/.arplist
    	fi
    else
	new_entry="$newarp - $(/opt/vyatta/bin/vyatta-op-cmd-wrapper show dhcp leases | grep "$newarp" | awk '{print $6}')"
    	logger -t [arp_notify] "New Device Detected -> $new_entry"
    	echo $new_entry >> $dir/.arplist
    fi
done

echo "" >> $dir/.arplist
echo "Removed ARP Entries" >> $dir/.arplist
for noarp in $(diff $dir/.arptable $dir/.arptablenew | grep - | grep ether | sed 's/^-//g' | awk '{print $1}')
do
    if [ -f $dir/.arpignore ]
    then
    	if [[ $(grep -L "$newarp" $dir/.arpignore) ]]; then
    		lost_entry="$noarp - $(/opt/vyatta/bin/vyatta-op-cmd-wrapper show dhcp leases | grep "$noarp" | awk '{print $6}')"
    		logger -t [arp_notify] "ARP Entry Removed -> $lost_entry"
    		echo $lost_entry >> $dir/.arplist
    	fi
    else
    	lost_entry="$noarp - $(/opt/vyatta/bin/vyatta-op-cmd-wrapper show dhcp leases | grep "$noarp" | awk '{print $6}')"
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
mv $dir/.arptablenew $dir/.arptable

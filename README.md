# arp_notify
A network device monitor Vyatta/EdgeMax routers to notify you via Pushover if new devices
join your network(s). Helpful if you frequently add things to your network and
need to know what was added without looking in dnsmasq log. 

Optional .arpignore file will not notify you about MAC addresses you "trust". 

Optional .arpnotify file to trigger webhooks if someone arrives/leaves. This
comes in handy with Hubitat and a [Virtual Presence
Sensor](https://github.com/bdwilson/hubitat/blob/master/Geofency-Presence/virtual-mobile-presence.groovy).
Create virtual presence devices per person and connect it to MakerAPI to use
with a webhook.

# Installation
<code>$ ssh admin@10.0.0.1</code> (or whatever your router IP is)<br>
<code>$ sudo su -</code><br>
<code># mkdir -p /config/arp_notify; cd /config/arp_notify</code><br>
<code># curl https://raw.githubusercontent.com/bdwilson/arp_notify/master/arp_notify.sh > arp_notify.sh</code><br>
<code># curl https://raw.githubusercontent.com/bdwilson/arp_notify/master/backup.sh > backup.sh</code><br>
<code># chmod 755 \*.sh</code><br>

Edit variables in arp_notify.sh to reflect your Pushover user token and app token (which you'll need to create). 

<code># crontab -e</code><br>
<pre>
23 11 * * * /config/arp_notify/backup.sh
*/5 * * * * /config/arp_notify/arp_notify.sh
</pre>

# Info
Q: Why are you storing things in /var/log?<br>
A: Because /var/log is stored in RAM vs. writing to SD every 5 minutes which may kill your SD card prematurely. Data is backed-up nightly to SD and restored upon reboot.<br>

Q: What do I need to do after a router firmware upgrade?<br>
A: Assuming you have the same config or are restoring from a config backup, you'll likely only need to reinstall the crontab entries above. First run of arp_notify.sh will restore the config from backup. 

Q: What if I have devices which I trust and never want to be notified about them?<br>
A: Create a file called .arpignore and put the MAC address (or the full entry
from .arptable file) into this file. Theoretically, you could copy .arptable to
.arpignore and ignore all devices from the getgo, then only be notified about
new things.

Q: How does the webhook work. 
A: Create a .arpnotify file.  The file should consist of a + or - depending on
if the webhook is for arrival or departing. Then the MAC address of the device,
then the webhook.  For instance:
<pre>
# more .arpnotify
# User 1 
+ f0:99:b6:ab:cd:12 http://192.168.1.16/apps/8/devices/1669/on?access_token=abcd-1234-xxxx-xxxx-xxxx
- f0:99:b6:ab:cd:12 http://192.168.1.16/apps/8/devices/1669/off?access_token=abcd-1234-xxxx-xxxx-xxxx
# User 2 
+ 74:b5:87:ab:cd:12 http://192.168.1.16/apps/8/devices/1670/on?access_token=abcd-1234-xxxx-xxxx-xxxx
- 74:b5:87:ab:cd:12 http://192.168.1.16/apps/8/devices/1670/off?access_token=abcd-1234-xxxx-xxxx-xxxx
</pre>

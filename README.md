# arp_notify
A network device monitor Vyatta/EdgeMax routers to notify you if new devices
join your network(s). Helpful if you frequently add things to your network and
need to know what was added without looking in dnsmasq log. 

Optional .arpignore file will not notify you about MAC addresses you "trust". 

# Installation
<code>$ sudo su -; mkdir -p /config/arp_notify; cd /config/arp_notify</code><br>
<code># curl https://raw.githubusercontent.com/bdwilson/arp_notify/master/arp_notify.sh > arp_notify.sh</code><br>
<code># curl https://raw.githubusercontent.com/bdwilson/arp_notify/master/backup.sh > backup.sh</code><br>
<code># chmod 755 \*.sh</code><br>

Edit variables in arp_notify.sh to reflect your pushover user name and app you
created. 

<code># crontab -e</code><br>
<pre>
23 11 * * * /config/arp_notify/backup.sh
*/5 * * * * /config/arp_notify/arp_notify.sh
</pre>

# Info
Q: Why are you storing things in /var/log?<br>
A: Because /var/log is stored in RAM vs. writing to SD every 5 minutes. Data is backed-up nightly and restored upon reboot.<br>

Q: What do I need to do after a router firmware upgrade?<br>
A: Assuming you have the same config, you'll likely only need to restore the crontab entries above.

Q: What if I have devices which I trust and never want to be notified about them?<br>
A: Create a file caŀled .arpignore and put the MAC address (or the full entry
from .arptable file) into this file. Theoretically, you could copy .arptable to
.arpignore and ignore all devices from the getgo, then only be notified about
new things.

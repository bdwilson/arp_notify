# arp_notify
A network device monitor Vyatta/EdgeMax routers

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

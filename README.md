# HOW TO TURN RASPBERRY PI 3 INTO A WIFI ACCESS POINT

To turn your raspberry pi 3 into a wifi access point please follow these steps. After several hours performing try and error, the steps outlined below finally worked for me.

## STEP 1

Open you raspberry pi terminal and perform an update

`sudo apt update`

after the update perform an upgrade by typing

`sudo apt upgrade`

## STEP 2

After the upgrade and update you need to install two software - hostapd and dnsmasq.
Hostapd is the software that starts the access point and also provides security and dnsmasq is the software that enables you set your DNS and IP address. Type

`sudo apt install hostapd && sudo apt install dnsmasq`

to install them.

## STEP 3

Once the installation,which will take a few seconds is complete we now dive into the configuration. In the terminal type

`sudo nano /etc/dhcpcd.conf`

and add the following lines to end of the file

```
interface wlan0
static ip_address=192.168.4.1/24
static router=192.168.4.1
static domain_name_servers=8.8.8.8
```

and save the file.You can replace wlan0 with the name of your  wifi adapter and also change the ip_address to any suitable to you (remember to also change the router to match the ip address). The lines added are used to set a static ip address for your wifi adapter.

## STEP 4

Next we are going to configure the dnsmasq server. But first,lets make a copy of the file **dnsmasq.conf**.

`sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig`

and press enter. After that we edit the dnsmasq.conf file

`sudo nano /etc/dnsmasq.conf`

add the following lines

```
interface=wlan0
domain-needed
bogus-priv
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
```
what the last line does is to set the range of ip_address that the connected devices will have. It also sets the subnet as well as a lease time of 24h.

## STEP 5

We now move on to configure the hostapd software which will be the information need to identify the access point such as the access point name,encryption type,passphrase and other necessary details. On the same terminal type

`sudo nano /etc/hostapd/hostapd.conf`

and add the following lines

```
interface=wlan0
driver=nl80211
ssid=myaccesspointname
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
ht_capab= [HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=mypassphrase
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
```

Change ssid to the name you want and change wpa_passphrase to any suitable password. RSN_pairwise sets the encryption of data to AES. Sometimes you will see **wpa_pairwise=TKIP** included in other tutorials. That is a less secure type of encryption,hence it should not be used.

## STEP 6

Now we need to tell hostapd where to find its configuration file.

`sudo nano /etc/default/hostapd`

and look for the line that says

`DAEMON CONF=""`

Change it to

`DAEMON CONF="/etc/hostapd/hostapd.conf"`


The next steps described are intended to allow packet forwarding via the Ethernet port. Since the wifi card will behave as an access point and devices connected will need to have access to the internet as well it means that the raspberry pi must also have access to the internet before it can share that internet access with the connected devices.

If you intend to provide the raspberry pi with internet access using a USB modem then you can ignore this.

## STEP 7

In the terminal open and edit the file in _/etc/sysctl.conf_

`sudo nano /etc/sysctl.conf`

and look for line

`#net.ipv4.ip_forward=1`

remove the comment so it becomes

`net.ipv4.ip_forward=1`

then save the file.

## STEP 8

Type in the terminal

`sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`

press enter

`sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT`

Press enter

`sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT`

Press enter

Replace _eth0_ and _wlan0_ with your device names. In most cases it will be the same.

## STEP 9

We need the rules in step 8 to run at boot time so we save them in a file and allow that file to start immediately the pi boots

`sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"`

to save the rules in a file called **/etc/iptables.ipv4.nat** and add it to the **rc.local** file

`sudo nano /etc/rc.local`

and just before the **exit 0** line add the following line

`iptables-restore < /etc/iptables.ipv4.nat `

and save the file.

## STEP 10

After everything reboot the pi.
You are now ready to connect to the access point with the wifi name and password you specified.

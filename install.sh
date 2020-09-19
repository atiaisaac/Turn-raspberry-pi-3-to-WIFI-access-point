#!/bin/bash

set -e

who=$(whoami)

# run as root
if [[ ${who} == "root" ]];then
	echo 
else
	echo "Script should be run as root"
	exit 1
fi

# update pi
apt update && apt -y upgrade

# install necessary software and disable
apt install -y hostapd
apt install -y dnsmasq

# disable hostapd and dnsmasq services
systemctl disable hostapd
systemctl disable dnsmasq

# configuring static ip for raspberry pi access point
if [[ -f /etc/dhcpcd.conf ]];then
	cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
	echo

	# wifi interface configuration
	echo "interface wlan0" >> /etc/dhcpcd.conf
	echo "	static ip_address=192.168.4.50/24" >> /etc/dhcpcd.conf
	# echo "	static routers=192.168.4.1" >> /etc/dhcpcd.conf
	# echo "	static domain_name_servers=192.168.4.1" >> /etc/dhcpcd.conf
	echo "	nohook wpa_supplicant" >> /etc/dhcpcd.conf

	# ethernet interface configuration
	echo "interface eth0" >> /etc/dhcpcd.conf
	echo "	static ip_address=192.168.5.50/24" >> /etc/dhcpcd.conf
	echo "	static routers=192.168.5.1" >> /etc/dhcpcd.conf
	echo "	static domain_name_servers=192.168.5.1" >> /etc/dhcpcd.conf
	
fi

service dhcpcd restart

# configuring range of ip address for connected devices
if [[ -f /etc/dnsmasq.conf ]];then
	cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak

	# wifi interface configuration
	echo "interface=wlan0" >> /etc/dnsmasq.conf
	echo "domain-needed" >> /etc/dnsmasq.conf
	echo "bogus-priv" >> /etc/dnsmasq.conf
	echo "dhcp-range=192.168.4.100,192.168.4.200,255.255.255.0,24h" >> /etc/dnsmasq.conf

	# ethernet interface configuration
	echo "interface=eth0" >> /etc/dnsmasq.conf
	echo "domain-needed" >> /etc/dnsmasq.conf
	echo "bogus-priv" >> /etc/dnsmasq.conf
	echo "dhcp-range=192.168.5.100,192.168.5.200,255.255.255.0,24h" >> /etc/dnsmasq.conf
	
fi

#set SSID password
wificonfig() {
	echo;echo;echo
	echo "This password will be used to ";echo "connect to the raspberry pi access point"
	echo "Password should be 8-63 characters for better security"
	read -p ">>> Enter your desired password:" wifipasswd
	echo;echo
	echo "You entered ${wifipasswd}"
	read -p ">>> Is this correct? y/n:" answer
	case ${answer} in 
	Y|y)
		echo 
		;;
	N|n)
		echo "Sticking with default password of 0123456789"
		echo "Note this may not be secure"
		echo "You can change the password later by locating"
		echo "the hostapd.conf file, changing the value of wpa_supplicant."
		echo "After which you restart your pi"  
		;;
	*)
		echo "Incorrect option"
		wificonfig
		;;
	esac
}

wificonfig

if [ -d /etc/hostapd ];then
	echo "Copying hostapd configuration file to hostapd folder"
	cp hostapd.conf /etc/hostapd
	sed -i "s/wpa_passphrase=0123456789/wpa_passphrase=${wifipasswd}/" /etc/hostapd/hostapd.conf
fi

# Pointing hostapd settings to hostapd configuration file
sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

# start hostapd
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd

# Turning on packet forwarding from network interface
# Either from ethernet or dialup modem to wifi interace
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf

# start dnsmasq
systemctl enable dnsmasq
systemctl start dnsmasq

# copy wvdial service to systemd folder
# this will make wvidal start on boot
cp sample.service /lib/systemd/system
systemctl daemon-reload
systemctl start sample.service

# configuring network address translation 
# replace ppp0 with interface of source of internet
# also replace wlan0 with the correct interface name
iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE  

# for WiFi interface
iptables -A FORWARD -i ppp0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o ppp0 -j ACCEPT

# for Ethernet interface
iptables -A FORWARD -i ppp0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o ppp0 -j ACCEPT

# saving iptabels rules to .nat file
sh -c "iptables-save > /etc/iptables.ipv4.nat"

# save your iptables rules and 
# start at boot time
echo "iptables-restore < /etc/iptables.ipv4.nat" >> /lib/dhcpcd/dhcpcd-hooks/70-ipv4.nat

# reboot system
read -n 1 -p "Press [Enter] to reboot"
echo ">> Rebooting <<"; reboot now

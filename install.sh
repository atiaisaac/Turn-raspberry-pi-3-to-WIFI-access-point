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
	echo "interface wlan0" >> /etc/dhcpcd.conf
	echo "	static ip_address=192.168.4.50/24" >> /etc/dhcpcd.conf
	# echo "	static routers=192.168.4.1" >> /etc/dhcpcd.conf
	# echo "	static domain_name_servers=192.168.4.1" >> /etc/dhcpcd.conf
	echo "	nohook wpa_supplicant" >> /etc/dhcpcd.conf
	
fi

service dhcpcd restart

# configuring range of ip address for connected devices
if [[ -f /etc/dnsmasq.conf ]];then
	cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
	echo "interface=wlan0" >> /etc/dnsmasq.conf
	echo "domain-needed" >> /etc/dnsmasq.conf
	echo "bogus-priv" >> /etc/dnsmasq.conf
	echo "dhcp-range=192.168.4.100,192.168.4.200,255.255.255.0,24h" >> /etc/dnsmasq.conf
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
		wificonfig 
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

# settting interfaces
interfaces() {
	echo
	echo "This is to help configure the"
	echo "source and destination interfaces to"
	echo "route data packets.eg eth0,wlan0,ppp0"
	read -p "Enter the interface name for input (source of internet): " source
	read -p "Enter the interface name for output: " destination
	if [[ $source == "ppp0" ]];then
		cp sample.service /lib/systemd/system
		systemctl daemon-reload
		systemctl enable sample.service
}

interfaces

# configuring network address translation 
# replace ppp0 with eth0 if using ethernet instead of dialup modem
iptables -t nat -A POSTROUTING -o $source -j MASQUERADE  
iptables -A FORWARD -i $source -o $destination -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $destination -o $source -j ACCEPT

# saving iptabels rules to .nat file
sh -c "iptables-save > /etc/iptables.ipv4.nat"

# save your iptables rules and 
# start at boot time
echo "iptables-restore < iptables.ipv4.nat" >> /lib/dhcpcd/dhcpcd-hooks/70-ipv4.nat

# reboot system
read -n 1 -p "Press [Enter] to reboot"
echo ">> Rebooting <<"; reboot now

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

uninstall() {
  echo "You are about to undo all changes related to RaspiAP"
  read -p "Press 'y' to proceed, 'n' to cancel:" option
  case $option in
  Y|y)
      echo
      ;;
  N|n)
      echo "Uninstall cancelled"
      exit 1
      ;;
  *)
      echo "Option not recognised"
      uninstall
      ;;
  esac
}

uninstall

if [[ -f /etc/dhcpcd.conf ]] && [[ -f /etc/dhcpcd.conf.bak ]];then
  rm /etc/dhcpcd.conf
  mv /etc/dhcpcd.conf.bak /etc/dhcpcd.conf
fi

if [[ -f /etc/dnsmasq.conf ]] && [[ -f /etc/dnsmasq.conf.bak ]];then
  rm /etc/dnsmasq.conf
  mv /etc/dnsmasq.conf.bak /etc/dnsmasq.conf
fi

if [[ -f /etc/hostapd/hostapd.conf ]];then
  rm /etc/hostapd/hostapd.conf
fi

sed -i 's/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/#DAEMON_CONF=""/' /etc/default/hostapd

sed -i "s/net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/" /etc/sysctl.conf

rm /lib/dhcpcd/dhcdpcd-hooks/70-ipv4.nat
rm /lib/systemd/system/sample.service

read -n 1 -p "Press [Enter] to reboot"
echo ">> Rebooting <<"; reboot now
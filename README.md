## Raspberry pi Access Point

I had a couple of raspberry pi 3 hardware and an old usb modem stick lying around and decided what I could make out of those. Then I remembered that I read an article some years back about how to make a wifi access point with a raspberry pi. This came quite at the right time because I was looking for a MIFI that I could use because I got tired of having to hotspot from my phone all the time. Plus it also drained a lot of my phone's battery power. So after experimenting with a couple of the resources I found online (whic was **A LOT** and many of them didn't work for me) I wrote a script to automate that for me and anyone else who might stumble across this project. At the time of writing I was using a raspbian buster. However I am confident it will work for raspberry pi jessie and beyond stretch since they all have sort of the same "OS layout".

The _*install.sh*_ script will turn your raspberry pi into a wifi access point. There a  lot of tutorials online about how to turn your raspberry pi into an access point, however after experimenting with a bunch of them, I finally had one that worked for me after countless tweaking. 

This version assumes that you are providing internet to the rpi through a dialup USB modem stick and then routing the packets from that to the wlan and ethernet interfaces. By doing so, devices connected to the access point will have connectivity to the internet without directly being connected to the USB modem.

You can also run the _*uninstall.sh*_ file to undo all the changes and your raspberry pi will go back to its default setting.


## NOTE

All scripts should be run as the root user. When using a usb modem, make sure to have wvdial installed first. Run it and save the profile it generates.

Future updates;

- Build a UPS for the setup so it can be battery powered
- Build an interface for easy setup and use.

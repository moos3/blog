+++
date = "2015-09-21T12:29:04-07:00"
draft = false
title = "dStar a Great Time!"
comments = true
image = ""
menu = ""
share = true
slug = "dstar-great-time"
tags = ["ham radio", "dstar"]

+++

So I have finally taken the jump in to d*Star. I picked up a Icom ID-51A Plus from the guys over at [Ham Radio Outlet](https://www.hamradio.com). Digital Modes
have interested me for a while. Since I live more than 30 miles from the nearest d*Star repeater, I picked up a DVAP 2meter Dongle. So my d*Star setup is a raspberry
pi b+ v2 + DVAP 2m and my Icom ID-51A Plus radio. So I'll explain how to get this setup. It took a lot of digging around the internet to get a complete set together.

### Configure Icom ID-51A Plus to use Dstar
So turn on your Icom ID-51A Plus. Press the menu button and nagivate to My Station and press the "blue" ok button in the middle of the dpad. Then Ok on My Call Sign. Then the first one should be selected by default. Press the Quick button and this will pop up with a menu of Edit and Clear. Click ok on edit. Now turn the little nob to navigate thought the alpha numeric options. Once your have your call sign in there click ok twice. This should take you back to My station list. Now aarow down to TXT Message. Select option 1. Press the quick button again. Put in your Name. Then ok twice again. Now we need put in a repeater for our dvap. Press and hold the DR button (Aka the Down Button.) Then highlight the From then press the ok button. Then ok on Repeater List. Scroll down to 20: Simplex. Next Press the Quick button and scroll down to Add and press the ok button. Set the Type: DV Repeater, scroll to Name, Use the small nob like you did to set your call sign, to give it the name of DVAP. Then scroll down to Use(From): Test this to yes. Next go to frequency and set it to a frequency that is available in your area. Remeber this as you will need this when we setup the PI + Dvap. Scroll down to Add to write and click ok. Now your DVAP should be in the From field. Next scroll to TO and Tell it ok and choose reflector. Then Ok on link to reflector. Then ok on Direct Input. Turn the small nob to a reflector number of your choosing. REF001C is busy reflector and REF050C is a busy one in the northeast of the US. Then click ok. Now our radio is ready. Next is the PI+DVAP setup.


### Setup Raspberry Pi and DVAP

So you will want to ssh to your raspberry pi as the pi user. I would recommend that you use the standard raspbian jessie image. You can get this at
[Downloads @ Raspberrypi.org](https://www.raspberrypi.org/downloads/raspbian/). You can follow their documentation on getting this on the SD card. Next you will
want to do ```apt-get update && apt-get upgrade``` to make sure you have everything is current. Next we need to install some supporting packages:
```
sudo apt-get install x11vnc vim libwxgtk2.8-0:armhf libwxgtk2.8-dev libwx-gtk2 libwx-gtk2u libwxbase2.8-0:armhf libwxbase2.8-dev libportaudio2:armhf libportaudiocpp0:armhf portaudio19-dev
```
 Next we will need to install klxupdate. This is going to handle installing all the correct packages needed for the repeater and gateway. So will run the following:

 ```
 wget http://www.westerndstar.co.uk/KLXstuff/klxupdate; sudo install -g bin -o root -m 0775 ./klxupdate "/usr/local/bin" ; sudo rm ./klxupdate
 ```
  Next we will install the repeater application using ```klxupdate repeater```. Select 9 to install the latest version and answer Y to the question. Repeater is fairly quick to install. Next will install the gateway application ```klxupdate gateway```. Select 9 to install the latest version and answer Y to the question. Gateway takes a few minutes to install. Next we need to make some desktop icons to make it easier to access the applications. So we are going to change Directory to ```cd /home/pi/Desktop```. So we are going to use vim to create these files. So run ```vim gateway.desktop``` and then paste

```
[Desktop Entry]
Name=ircDDBGateway
Comment=Application for running ircDDBgateway
Exec=sudo ircddbgateway -gui
Icon=/usr/share/pixmaps/openbox.xpm
Terminal=false
Type=Application
```

Then hit esc then `:wq` this will write the file out and quit vim. Next we are going to create gateway_config.desktop using vim ```vim gateway_config.desktop```. We are going to paste the following that file:

```
[Desktop Entry]
Name=Gateway Config
Comment=Application for configuring ircDDBGateway
Exec=sudo ircddbgatewayconfig
Icon=/usr/share/pixmaps/obconf.xpm
Terminal=false
Type=Application
```

Then hit esc then `:wq` this will write the file out and quit vim.
Next is dstar.desktop, we need to make also make this in vim using that same steps as before. Then we are going to paste the following in that file:

```
[Desktop Entry]
Name=D-Star Repeater
Comment=Application for running D-Star
Exec=sudo dstarrepeater -gui
Icon=/usr/share/pixmaps/openbox.xpm
Terminal=false
Type=Application
```

Then we are going to create dstar_config.desktop using the same process as the last 3 files before. Then we are going to paste the following into the file:

```
[Desktop Entry]
Name=D-Star Config
Comment=Application for configuring D-Star Repeater
Exec=sudo dstarrepeaterconfig
Icon=/usr/share/pixmaps/obconf.xpm
Type=Application
```

Next we are going to setup x11vnc, so we can remote into the pi and use the gui tools to configure the tools. While we are still ssh'd into the pi. We are going to setup x11vnc password. We are going to run ```x11vnc -storepasswd``` next we need to make it so vnc starts with the pi. We are going to change directories to ```cd /etc/init.d/``` then we are going to use wget again to download a init script. ```wget http://www.vk3erw.com/download/vncboot``` Next we need to make it executable using the following command `chmod 775 /etc/init.d/vncboot` now that have it executable. We need to update the system defaults, using ```update-rc.d vncboot defaults```. Next we need to update `/boot/config.txt`. We need to do this becuase without a HDMI monitor connected you may find the VNC session results in a very small screen. This is due to the default graphics mode on boot. You can force a larger screen by modifying /boot/config.txt:

```
sudo vim /boot/config.txt
```

Uncomment and modifying the following lines:

```
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=58
```

Next we are going to reboot the pi. ```sudo reboot```.


#### Configure applications

First we are going to configure the gateway. So VNC to the the pi using a vnc client like chicken of vnc(on mac os x). We are going to double click on gateway_config. Its going to take a bit to getting up on the screen. Once up on the screen we are going to make some changes, to what we see on the screen. We are going to set the drop down box to `hotspot`. Next we are going to set the callsign to our callsign. Next boxes we are going to touch are the QTH to your location. Next we are going to the Reapter 1 tab. We are going to set the Band to C for 2m or B for 70cm. The type needs to be set to Homebrew. If you want to automatically link to a reflector, then set the Reflector to the reflector you want and the band. You want to set Startup to yes in this case. On the next Repeater make sure that Freq, offset, Range, AGL, Lat and Long are all set to 0. Next we are going to click the right arrow until we are get to ircDDB tab. Set ircDDB to Enabled and hostname to freestar-irc-cluster.v3lsr.ca, put your callsign in for the username. Since this server doesn't need you to register your callsign. Next click the right aarow again to D-PRS and set it to enable. If the hostname is blank put in rotate.aprs2.net and port 14580. Next click the right arrow again for DExtra, set it to Enabled if you wish to use DExtra. Click the right aarow to go to D-Plus and set this to enable and set Login to your callsign. Click the Right Arrow again to bring you to the DCS and CCS tab. Set DCS and CCS to Enabled. Next click the right arrow until you get to the end of the tabs. Set info command, echo command, gui log, D-Rats, DTMF Control all to Enabled. Next go to File -> Save. Now close this window.

Next double click on D-Star Config on the Desktop. Once the window opens up. We are going to set callsign and gateway to our callsign. Next to the callsign field is a drop which is the bands and in my case since a I have 2meter DVAP I have this set to C. Mode you want to set to Simplex. Also want to make Restrict, RTP1 Validation to Off. DTMF Blanking and Error Reply set to ON. Click on beacon to every 10 minutes, Put your callsign plus the band in the message. Enable the Voice and set the langauge of your country. Click the right aarow to Control 1. We are going enable Enabled. Set RPT1 Callsign to RPTRCTLC and RPT2 Callsign to K1MOS<space>G. Now Click on the Modem tab and set the type to DVAP. Now click Configure... button. Set port to /dev/ttyUSB0 or the port that the DVAP is using. Set the Band to the band for your dvap. Next we need to pick a frequency that isn't being used near you. So check your repeater lists, next the with the frequency scanner of your radio. Set the power to 10 dBm and squelch to -100dBm. Click on ok. Then file -> save.

Next click on ircDDBGateway and wait for it to connect. Once it says ircDDB Connected and Reapter 1 is linked. Then double click on D-Star Repeater. You should see Status RX State: Listening. To make sure its connected.

To Test this Turn on your radio to the Freq that you have chosen. Key the radio and you should see the traffic from your Dstar Radio in this window.

Next now that we have the radio configured we want to setup the pi to automatically start these applications.

Open a Terminal applicaiton or ssh to the pi. Execute the following commands.

```
sudo su -
cd /home/pi/.config/autostart
vim start_gateway.desktop
```
Paste the following in there:

```
[Desktop Entry]
Type=Application
Exec=sudo ircddbgateway -gui
```
Save this with the `:wq`. Next we are going to create another file called ```start_repeater.desktop```. Paste the following into the file and save it.

```
[Desktop Entry]
Type=Application
Exec=sudo dstarrepeater -gui
```
Now the Hotspot/Repeater will start automatically.

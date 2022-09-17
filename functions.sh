#!/usr/bin/env bash

#Functions

#Update
update_sys () {
	apt update && apt upgrade -y
	apt autoremove -y && apt clean -y && apt autoclean -y
}

#Change repo to testing
jump_testing () {
	loc=/etc/apt/sources.list
	mv $loc $loc.backup
	cat<<EOT >> $loc
# Debian Testing repos
deb http://deb.debian.org/debian/ testing main contrib non-free
# Security updates for testing
deb http://security.debian.org testing-security main contrib non-free
EOT
}

#Install NetworkManager
internet_install () {
	apt install -y network-manager
	systemctl enable --now NetworkManager
	sed -i '11,12 s/^/#/' /etc/network/interfaces
}

#Microcode Installation and other firmware
microcode_install () {
	#Install microcode for Intel
	if lscpu | grep -q "GenuineIntel"; then
		printf "Intel Processor detected\n"
		apt install -y intel-microcode
	#Install microcode for AMD
	elif lscpu | grep -q "AuthenticAMD"; then
		printf "AMD Processor detected\n"
		apt install -y amd64-microcode
	else
		printf "HOW IS THIS POSSIBLE?\n"
	fi
	apt install -y firmware-misc-nonfree initramfs-tools
}

#Xorg Installation
xorg_install () {
	#ALSA libraries 
	apt install -y libasound2 libasound2-data alsa-utils alsa-oss alsa-firmware-loaders alsa-tools alsa-topology-conf alsa-ucm-conf
	#Basic Xorg Install
	apt install -y libgl1 libgl1-mesa-dri libglu1-mesa mesa-utils mesa-vulkan-drivers libvulkan1 vulkan-tools vulkan-validationlayers x11-session-utils x11-utils x11-xkb-utils x11-xserver-utils xauth xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable xfonts-utils xkb-data xserver-xorg-core xserver-xorg-input-all xserver-xorg-legacy x11-xfs-utils x11-common xorg-docs kitty
	#Intel (VA-API VDPAU)
	if lspci | grep "VGA" | grep -q "Intel"; then
		apt install -y intel-media-va-driver-non-free libvdpau-va-gl1 mesa-vdpau-drivers vainfo vdpauinfo intel-gpu-tools
#		apt install -y i965-va-driver-shaders libvdpau-va-gl1 mesa-vdpau-drivers vainfo vdpauinfo intel-gpu-tools
	#KVM/QEMU xorg driver
	elif lspci | grep "VGA" | grep -q "Red Hat, Inc."; then
		apt install -y xserver-xorg-video-qxl
	fi
	#Audio libraries and PulseAudio
 apt install -y libasound2-plugins pulseaudio pulseaudio-utils
}

#Push Wallpapers
wallpapers () {
	if [[ -d /usr/share/backgrounds ]];then
		cp -r Debian /usr/share/backgrounds
	elif [[ -d /usr/share/wallpapers ]]; then
		cp -r Debian /usr/share/wallpapers
	else
		mkdir /usr/share/backgrounds
		cp -r Debian /usr/share/backgrounds
	fi
}

#Yaru Colors by:Jannomag
yaru_colors () {
	if [[ ! -d /usr/bin/git ]]; then
		apt install -y git
	fi
	git clone https://github.com/Jannomag/Yaru-Colors
	cp -r Yaru-Colors/Themes/Yaru-Red-dark/ /usr/share/themes
	rm -rf Yaru-Colors
}

#Papirus Icon Theme Installation
papirus_install () {
	link=$(curl -s https://api.github.com/repos/PapirusDevelopmentTeam/papirus-icon-theme/releases/latest | jq '.tarball_url')
	aria2c -o ext.tar.gz ${link:1:-1}
	tar -xf ext.tar.gz
	dir=$(ls | grep "Papirus") 
	cp -r $dir/{Papirus{,-Light,-Dark},ePapirus{,-Dark}} /usr/share/icons/
	gtk-update-icon-cache /usr/share/icons/Papirus
	gtk-update-icon-cache /usr/share/icons/Papirus-Light
	gtk-update-icon-cache /usr/share/icons/Papirus-Dark
	gtk-update-icon-cache /usr/share/icons/ePapirus
	gtk-update-icon-cache /usr/share/icons/ePapirus-Dark
	wget -qO- https://git.io/papirus-folders-install | sh
	rm -rf ext.tar.gz $dir
	papirus-folders -C carmine --theme Papirus-Dark
}

#Oreo cursor install
oreo_install () {
	tar -xf oreo-red-cursors.tar.gz
	mv oreo_red_cursors /usr/share/icons
}

#Install Redshift
redshift_install () {
	apt install -y redshift redshift-gtk
	cat<<EOT >> /etc/redshift.conf
[redshift]
temp-day=3800
temp-night=3800
location-provider=manual
[manual]
lat=40.6
lon=70.0
EOT
}

#LightDM install 
lightdm_install () {
	apt install --no-install-recommends -y lightdm
	apt install -y slick-greeter
	#LightDM Config
	mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bk
	cat<<EOT >> /etc/lightdm/lightdm.conf
[LightDM]
[Seat:*]
greeter-session=slick-greeter
greeter-hide-users=false
display-setup-script=/etc/lightdm/auto.sh
[XDMCPServer]
[VNCServer]
EOT
	cat<<EOT >> /etc/lightdm/auto.sh
#! /bin/sh
redshift &
EOT
	chmod +x /etc/lightdm/auto.sh
	if lspci | grep "VGA" | grep -q "Red Hat, Inc."; then
		echo "xrandr --output Virtual-1 --mode 1360x768" >> /etc/lightdm/auto.sh
	fi
	cat<<EOT >> /etc/lightdm/slick-greeter.conf
[Greeter]
draw-user-backgrounds=false
theme-name=Yaru-Red-dark
icon-name=Papirus-Dark
font-name=Ubuntu Regular 11
background=/usr/share/backgrounds/Debian/DebianRed.jpg
EOT
	systemctl enable lightdm
}

#Kitty Config
kitty_config () {
	apt install -y fonts-ubuntu
	mkdir -p /home/$1/.config
	cp -r kitty /home/$1/.config/
}

#Fix Config
fix_config () {
	chown $1:$1 /home/$1/.config
	chown -R $1:$1 /home/$1/.config/*
}

#XFCE Installation and config
xfce_install () {
	#Actual XFCE
	apt install -y --no-install-recommends thunar thunar-archive-plugin xarchiver 
	apt install -y libxfce4ui-utils dbus-user-session dbus-x11 gvfs gvfs-backends libxfce4panel-2.0-4 policykit-1-gnome thunar-volman tumbler tumbler-plugins-extra udisks2 xdg-user-dirs thunar-media-tags-plugin xfce4-appfinder xfce4-panel xfce4-pulseaudio-plugin xfce4-session xfce4-settings xfconf xfdesktop4 xfwm4 fonts-quicksand xfce4-notifyd xfce4-power-manager xfce4-power-manager-plugins pavucontrol ristretto xfce4-battery-plugin xfce4-clipman-plugin xfce4-datetime-plugin xfce4-fsguard-plugin xfce4-places-plugin xfce4-screenshooter xfce4-sensors-plugin xfce4-wavelan-plugin xfce4-whiskermenu-plugin
	#Wallpapers
	wallpapers
	#Yaru Red Dark / Papirus Icons / Oreo Cursor
	yaru_colors
	papirus_install
	oreo_install
	#Redshift / LightDM
	redshift_install
	lightdm_install
	#Config XFCE
	mkdir -p /home/$1/.config
	cp -r xfce4/* /home/$1/.config/xfce4/
	#Config
	kitty_config $1
	fix_config $1
}

#KDE Installation and config
kde_install () {
	#Actual KDE
	apt install -y --no-install-recommends plasma-desktop plasma-workspace sddm dolphin gwenview
	apt install -y bluedevil breeze-gtk-theme fonts-hack fonts-noto ibus-data kde-config-gtk-style kde-config-screenlocker kde-config-sddm kde-style-oxygen-qt5 kgamma5 khelpcenter khotkeys kinfocenter kio-extras kmenuedit kscreen ksshaskpass kwin-x11 kwrited libpam-kwallet5 plasma-browser-integration plasma-discover plasma-disks plasma-nm plasma-pa plasma-systemmonitor plasma-thunderbolt plasma-vault powerdevil systemsettings xdg-desktop-portal-kde kde-cli-tools powerdevil systemsettings udisks2 upower haveged libpam-systemd sddm-theme-breeze kdeconnect kwrite kfind keditbookmarks kdialog ffmpegthumbs kdegraphics-thumbnailers kimageformat-plugins dolphin-plugins kamera qt5-image-formats-plugins kde-spectacle plasma-dataengines-addons plasma-runners-addons plasma-wallpapers-addons plasma-widgets-addons polkit-kde-agent-1 sweeper 
	#Wallpapers
	wallpapers
	#Config
	kitty_config $1
	fix_config $1
}

#Fluxbox Installation and config
fluxbox_install () {
	apt install -y fluxbox fbautostart fbpager feh lxappearance rofi pavucontrol xterm
	#Use MenuMaker
	aria2c -o temp.tar.gz https://sourceforge.net/projects/menumaker/files/latest/download
	tar -xf temp.tar.gz
	dir=$(ls | grep menumaker)
	cd $dir
	./configure && make && make install
	cd ..
	rm -rf $dir temp.tar.gz
	mmaker -f fluxbox -t xterm
	#Yaru Red Dark / Papirus Icons / Oreo Cursor
	yaru_colors
	papirus_install
	oreo_install
	#Redshift / LightDM
	redshift_install
	lightdm_install
	#Config
	kitty_config
	fix_config
}

#Brave browser and extentions download
brave_install () {
	if apt search apt-transport-https | grep -q "installed"; then
		printf "Installing Brave\n"
	else
		apt install -y apt-transport-https
	fi
	curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|tee /etc/apt/sources.list.d/brave-browser-release.list
	apt update && apt install brave-browse -y
	chrome_ext $1
}

#Ungoogled chrome and extentions download
chrome_install () {
	if [[ ! -d /usr/bin/flatpak ]]; then
		sudo apt install flatpak
		flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	fi
	sudo flatpak install com.github.Elonston.UngoogledChromium	
	chrome_ext $1
}

#Firefox and extentions download
firefox_install () {
	apt install -y firefox-esr
	mkdir -p /home/$1/.config/firefox-ext
	#Download darkreader
	loc=$(curl -s https://api.github.com/repos/darkreader/darkreader/releases/latest | jq '.assets[2]' | jq '.browser_download_url')
	aria2c -o darkreader.xpi ${loc:1:-1}
	mv darkreader.xpi /home/$1/.config/firefox-ext
	#Download uBlock
	loc=$(curl -s https://api.github.com/repos/gorhill/uBlock/releases/latest | jq '.assets[1]' | jq '.browser_download_url')
	aria2c -o uBlock.xpi ${loc:1:-1}
	mv uBlock.xpi /home/$1/.config/firefox-ext
	#Config
	fix_config $1
}

#Chrome Extentions
chrome_ext () {
	#Download darkreader
	loc=$(curl -s https://api.github.com/repos/darkreader/darkreader/releases/latest | jq '.assets[1]' | jq '.browser_download_url')
	aria2c -o ext.zip ${loc:1:-1}
	mkdir -p /home/$1/.config/chrome-ext/darkreader
	unzip -d /home/$1/.config/chrome-ext/darkreader ext.zip
	rm -rf ext.zip
	#Download uBlock
	loc=$(curl -s https://api.github.com/repos/gorhill/uBlock/releases/latest | jq '.assets[0]' | jq '.browser_download_url')
	aria2c -o ext.zip ${loc:1:-1}
	unzip -d ext.zip
	dir=$(ls | grep "uBlock") && mv dir /home/$1/.config/chrome-ext/uBlock
	rm -rf ext.zip
	#Config
	fix_config $1
}

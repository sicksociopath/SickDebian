#!/usr/bin/env bash 

#Functions
source functions.sh

#Get User Name
read -p "Enter username: " un
printf "\n"

#Upgrade // Use Stable or Testing
num=0
while [[ num -ne 1 ]]
do
	printf "Select Debian version:\n"
	printf "1) Stable\n"
	printf "2) Testing\n"
	read -p "Insert option: " debiantype
	if (($debiantype>=1 && $debiantype <=2)); then
		num=1
	else
		printf "Invalid. Try again\n"
	fi
done

#Desktop install
num=0
while [[ num -ne 1 ]]
do
	printf "Select Desktop Env:\n"
	printf "1) KDE\n"
	printf "2) XFCE\n"
	printf "3) Fluxbox\n"
	printf "4) None\n"
	read -p "Insert option: " desktopenv
	if (($desktopenv>=1 && $desktopenv <=4)); then
		num=1
	else
		printf "Invalid. Try again\n"
	fi
done

#Browser Install
num=0
while [[ num -ne 1 ]]
do
	printf "Choose web browser\n"
	printf "1) brave\n"
	printf "2) chromium\n"
	printf "3) firefox\n"
	printf "4) none\n"
	read -p "Option: " browsersel
	if (($browsersel>=1 && $browsersel <=4)); then
		num=1
	else
		printf "Invalid. Try again\n"
	fi
done

case $debiantype in
	1)
		printf "Updating and Upgrading\n"
		update_sys
		num=1
	;;
	2)
		printf "Changing to Testing repo\n"
		jump_testing
		update_sys
		num=1
	;;
esac

#Install terminal based tools
apt install -y neofetch --no-install-recommends
apt install -y build-essential git htop jq aria2 zip unzip curl ssh sudo vim mtools acpi acpid dosfstools dialog avahi-daemon wget

#Enable avahi and and acpid
systemctl enable avahi-daemon
systemctl enable acpid

#Add user to sudo
usermod -aG sudo $un

#Internet install
internet_install

#Install microcode
microcode_install

#Install DE
case $desktopenv in
	1)
		printf "Install KDE Plasma\n"
		xorg_install
		#kde_install $un
		#apt install -y keepassxc mpv thunderbird yt-dlp torbrowser-launcher
		num=1
	;;
	2)
		printf "Install XFCE\n"
		xorg_install
		xfce_install $un
		apt install -y keepassxc mpv thunderbird yt-dlp torbrowser-launcher
		num=1
	;;
	3)
		printf "Install Fluxbox\n"
		xorg_install
		fluxblox_install $un
		apt install -y keepassxc mpv thunderbird yt-dlp torbrowser-launcher
		num=1
	;;
	4)
		num=1
	;;
esac

#Install Browser
case $browsersel in
	1)brave_install $un
		num=1
	;;
	2)chrome_install $un
		num=1
	;;
	3)firefox_install $un
		num=1
	;;
	4)num=1
	;;
	*)printf "Invalid options\nTry again\n"
	;;
esac

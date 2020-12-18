#!/bin/bash
die() {
	echo -e "\e[0;31mSomething went wrong...\e[0m"
	exit 1
}
dir="$HOME/.lenovo_v330_helper"
if [ "$1" == remove ]; then rm -rf $dir; fi
if [ "$1" == change ]; then rm -f $dir/distro; fi
echo -e "Lenovo V330 Linux helper"
if [ ! -f $dir/distro ]; then
echo -e "\e[0;33m   Choose your Linux distro:\e[0m"
cat <<EOF
1. Arch Linux
2. Ubuntu/Debian like
	P.S. You can change it later, by executing ./helper.sh change
EOF
read -rp "> " distro
case "$distro" in
	1 | A* | arch*)
		distro_=Arch
		PM_INSTALL() {
			sudo pacman -S "$@" --noconfirm
		}
		PM_REMOVE() {
			sudo pacman -Rs "$@" --noconfirm
		}
		PM_QUERY() {
			if pacman -Qq "$@" &>/dev/null; then return 0; else return 1; fi
		}
		;;
	2 | U* | D* | debian* | ubuntu*)
		distro_=Deb
		PM_INSTALL() {
			sudo apt install "$@" -y
		}
		PM_REMOVE() {
			sudo apt purge "$@" -y
		}
		PM_QUERY() {
			if dpkg -s "$@" &>/dev/null; then return 0; else return 1; fi
		}
		;;
	*)
		echo "Unknown distribution."
		exit 1
		;;
esac
[ -f $dir/distro ] || echo $distro_ > $dir/distro
else distro_="$(cat $dir/distro)"
fi
if [ ! -d "$dir" ]; then
	mkdir -p $dir
	mkdir -p $dir/{status,backup}
fi
for status in 1 2 3 4 5 6 7 8 9; do
	if [ -f $dir/status/$status ]; then
		if [ "$(cat $dir/status/$status)" == 1 ]; then
			eval status${status}="O"
		else
			eval status${status}="X"
		fi
	else
		eval status${status}="X"
	fi
done

echo -e "\e[0;32m   Choose what to do:\e[0m"
cat <<EOF
1. Fix 'dummy output' on ALSA/PulseAudio		($status1)
2. Install xf86-video-intel instead modesetting		($status2)
3. Fix tearing						($status3)
4. Enable Bluetooth auto-connect			($status4)
5. Switch notebook to performance mode (governor)	($status5)
6. Remove spam from 'iwlwifi' from logs			($status6)
7. Turn off the beeping thing (PC Speaker)		($status7)
8. Try to fix bluetooth headphones on PulseAudio	($status8)
9. Install new 'Mesa' driver (iris instead of i915)	($status9)
EOF
read -rp "> " action
case "$action" in
	1)
		if [ "$status1" = "O" ]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			sudo mv $dir/backup/alsa.conf /etc/modprobe.d/alsa.conf 2>/dev/null
			echo 0 >$dir/status/1
			exit 0
		else
			[ -f /etc/modprobe.d/alsa.conf ] && cp /etc/modprobe.d/alsa.conf $dir/backup/alsa.conf
			cat <<EOF | sudo tee -a /etc/modprobe.d/alsa.conf || die
options snd-hda-intel model=auto
EOF
			echo "Done!"
			echo 1 >$dir/status/1
			exit 0
		fi
		;;
	2)
		if [ "$status2" = "O" ]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			case "$distro_" in
				Arch) PM_REMOVE xf86-video-intel 2>/dev/null ;;
				Deb) PM_REMOVE xserver-xorg-video-intel 2>/dev/null ;;
			esac
			sudo mv $dir/backup/20-intel.conf /etc/X11/xorg.conf.d/20-intel.conf 2>/dev/null
			echo 0 >$dir/status/2
		else
			case "$distro_" in
				Arch) PM_QUERY xf86-video-intel || PM_QUERY xf86-video-intel-git || PM_INSTALL xf86-video-intel || die ;;
				Deb) PM_QUERY xserver-xorg-video-intel || PM_INSTALL xserver-xorg-video-intel || die ;;
			esac
			[ -f /etc/X11/xorg.conf.d/20-intel.conf ] && cp /etc/X11/xorg.conf.d/20-intel.conf $dir/backup/20-intel.conf
			cat <<EOF | sudo tee /etc/X11/xorg.conf.d/20-intel.conf || die
Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
   Option      "AccelMethod"  "sna"
EndSection
EOF
			echo "Done!"
			echo 1 >$dir/status/2
			exit 0
		fi
		;;
	3)
		if [[ "$status3" = "O" ]]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			if [ -f /etc/X11/xorg.conf.d/20-intel.conf ]; then
				sudo sed '/[[:blank:]]*Option.*TearFree.*true/d' -i /etc/X11/xorg.conf.d/20-intel.conf || die
			fi
			echo 0 >$dir/status/3
			exit 0
		else
			[ ! -f /etc/X11/xorg.conf.d/20-intel.conf ] && {
				echo "Apply fix n.2 first (xf86-video-intel)"
				exit 0
			}
			sudo sed '/^EndSection/i \ \ \ Option "TearFree" "true"' -i /etc/X11/xorg.conf.d/20-intel.conf || die
			echo "Done!"
			echo 1 >$dir/status/3
			exit 0
		fi
		;;
	4)
		if [[ "$status3" = "O" ]]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			sudo mv $dir/backup/main.conf /etc/bluetooth/main.conf 2>/dev/null
			sudo systemctl restart bluetooth
			echo 0 >$dir/status/4
			exit 0
		else
			PM_QUERY bluez || PM_INSTALL bluez || die
			[ -f /etc/bluetooth/main.conf ] && cp /etc/bluetooth/main.conf $dir/backup/main.conf
			if [ "$(grep -o ".*AutoEnable=.*" /etc/bluetooth/main.conf 2>/dev/null)" ]; then
				sudo sed 's/.*AutoEnable=.*/AutoEnable=true/g' -i /etc/bluetooth/main.conf || die
			fi
			if [ ! -f /etc/bluetooth/main.conf ]; then
				cat <<EOF | sudo tee /etc/bluetooth/main.conf || die
AutoEnable=true
EOF
			fi
			if [ "$(grep -o ".*DiscoverableTimeout = .*" /etc/bluetooth/main.conf)" ]; then
				sudo sed 's/.*DiscoverableTimeout = .*/DiscoverableTimeout = 0/g' -i /etc/bluetooth/main.conf || die
			else
				cat <<EOF | sudo tee -a /etc/bluetooth.main.conf || die
DiscoverableTimeout = 0
EOF
			fi
			sudo systemctl restart bluetooth
			echo "Done!"
			echo 1 >$dir/status/4
			exit 0
		fi
		;;
	5)
		if [ "$status5" = "O" ]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			case "$distro_" in
				Arch)
					PM_QUERY cpupower && PM_REMOVE cpupower 2>/dev/null
					PM_INSTALL cpufrequtils
					;;
				Deb)
					PM_QUERY linux-tools-common && PM_REMOVE linux-tools-common
					PM_INSTALL cpufrequtils 2>/dev/null
					;;
			esac
			sudo systemctl disable cpupower-set
			sudo systemctl restart cpupower 2>/dev/null
			sudo rm /etc/systemd/system/cpupower-set.service
			echo 0 >$dir/status/5
			exit 0
		else
			###
			case "$distro_" in
				Arch)
					PM_QUERY cpufrequtils && PM_REMOVE cpufrequtils
					PM_QUERY cpupower || PM_INSTALL cpupower || die
					;;
				Deb)
					PM_QUERY cpufrequtils && PM_REMOVE cpufrequtils
					PM_QUERY linux-tools-common || PM_INSTALL linux-tools-common || die
					;;
			esac
			cat <<EOF | sudo tee /etc/systemd/system/cpupower-set.service || die
[Unit]
Description=Set performance governor
Before=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g performance

[Install]
WantedBy=multi-user.target
EOF
			sudo systemctl enable --now cpupower-set || die
			echo "Done!"
			echo 1 >$dir/status/5
			exit 0
		fi
		;;
	6)
		if [ "$status6" = "O" ]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			sudo rm /etc/modprobe.d/iwlwifi-spam.conf
			echo 0 >$dir/status/6
			exit 0
		else
			cat <<EOF | sudo tee /etc/modprobe.d/iwlwifi-spam.conf || die
options iwlwifi power_save=0
options iwlmvm power_scheme=1
EOF
			echo "Done!"
			echo 1 >$dir/status/6
			exit 0
		fi
		;;
	7)
		if [ "$status7" = "O" ]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			sudo mv $dir/backup/pcspkr.conf /etc/modprobe.d/pcspkr.conf 2>/dev/null
			echo 0 >$dir/status/7
			exit 0
		else
			[ -f /etc/modprobe.d/pcspkr.conf ] && cp /etc/modprobe.d/pcspkr.conf $dir/backup/pcspkr.conf
			cat <<EOF | sudo tee /etc/modprobe.d/pcspkr.conf || die
blacklist pcspkr
EOF
			echo "Done!"
			echo 1 >$dir/status/7
			exit 0
		fi
		;;
	8)
		if [ "$status8" = "O" ]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			sudo mv $dir/backup/default.pa /etc/pulse/default.pa 2>/dev/null
			sudo systemctl restart bluetooth
			echo 0 >$dir/status/8
			exit 0
		else
			[ -f /etc/pulse/default.pa ] && cp /etc/pulse/default.pa $dir/backup/default.pa
			if [ "$(grep -o ".*load-module module-switch-on-connect.*" /etc/pulse/default.pa)" ]; then
				sudo sed 's/.*load-module module-switch-on-connect.*/load-module module-switch-on-connect/g' -i /etc/pulse/default.pa || die
			fi
			sudo systemctl restart bluetooth
			echo "Done!"
			echo 1 >$dir/status/8
			exit 0
		fi
		;;
	9)
		if [ "$status9" = "O" ]; then
			read -rp "This fix has already been applied. Restore to original condition? [y/N]: " ask
			case "$ask" in "" | N* | n*) exit 0 ;; Y* | y*) RESTORE=1 ;; *) exit 1 ;; esac
		else
			RESTORE=0
		fi
		if [ "$RESTORE" == 1 ]; then
			sudo sed "/MESA_LOADER_DRIVER_OVERRIDE=iris/d" -i /etc/environment || die
			echo 0 >$dir/status/9
			exit 0
		else
			echo "MESA_LOADER_DRIVER_OVERRIDE=iris" | sudo tee -a /etc/environment || die
			echo "Done!"
			echo 1 >$dir/status/9
			exit 0
		fi
		;;
esac

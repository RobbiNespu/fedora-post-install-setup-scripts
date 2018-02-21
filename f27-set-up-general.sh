#!/bin/bash

#=======================================================================================
#
#         FILE: XXXXX.sh
#
#        USAGE: XXXXX.sh
#
#  DESCRIPTION: Post-installation Bash script for Fedora 27 Workstation General
#      WEBSITE:
#
#      OPTIONS: see function ’usage’ below
# REQUIREMENTS: Fedora installed on your computer
#         BUGS: ---
#        NOTES: After installation you may perform these additional tasks:
#             - Firefox "about:support" what is compositor? If 'basic' open "about:config"
#               find "layers.acceleration.force-enabled" and switch to true, this will
#               force OpenGL acceleration
#             - Add scripts directory to path > add :$HOME/scripts to PATH in.bash_profile
#             - Install HTTPS everywhere, privacy badger, ublock origin in Firefox/Chromium
#             - Consider "sudo dnf install kernel-tools", "sudo cpupower frequency-set --governor performance"
#             - Files > preferences > views > sort folders before files
#             - Change shotwell import directory format to %Y/%m + rename lower case, import photos from external drive
#             - UMS > un-tick general config > enable external network + check force network on interface is correct network (wlp2s0)
#       AUTHOR: David Else
#      COMPANY: Else Web Development
#      VERSION: 1.0
#      CREATED: 11-7-17
#     REVISION: 28-12-17
#=======================================================================================

read -rp "What would you like this computer to be called (hostname)? " hostname
hostnamectl set-hostname "$hostname"

# Enable repositories
sudo su -c 'dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm'
# sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/26/winehq.repo and install winehq-stable

# Update everything
echo "Updating Fedora..."
sudo dnf -y --refresh upgrade

echo "Installing packages..."
sudo dnf -y install libva-intel-driver gstreamer1-vaapi gstreamer1-libav ffmpeg mpv \
	fuse-exfat gnome-tweak-tool gnome-shell-extension-auto-move-windows.noarch gnome-shell-extension-pomodoro \
	java-1.8.0-openjdk keepassx transmission-gtk mkvtoolnix-gui borgbackup \
	freetype-freeworld lshw mediainfo dolphin-emu mame virt-manager klavaro jack-audio-connection-kit

# Add some alias
cat >>"$HOME/.bashrc" <<EOL
alias ls="ls -ltha --color --group-directories-first" # l=long listing format, t=sort by modification time (newest first), h=human readable sizes, a=print hidden files
alias tree="tree -Catr --noreport --dirsfirst --filelimit 100" # -C=colorization on, a=print hidden files, t=sort by modification time, r=reversed sort by time (newest first)
EOL

# Change some desktop settings
gsettings set org.gnome.settings-daemon.plugins.media-keys max-screencast-length 0 # Ctrl + Shift + Alt + R to start and stop screencast
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.session idle-delay 1200
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:backspace', 'terminate:ctrl_alt_bksp']"
gsettings set org.gnome.shell.extensions.auto-move-windows application-list "['org.gnome.Nautilus.desktop:2', 'org.gnome.Terminal.desktop:3', 'code.desktop:1', 'firefox.desktop:1', 'wine.desktop:4']" # for the gnome-shell-extension-auto-move extension

# Allow virtual machines that use fusefs to intall properly with SELinux
sudo setsebool -P virt_use_fusefs 1

# Increase the amount of inotify watchers for live-server and audio
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# Set subpixel hinting for freetype-freeworld
gsettings set org.gnome.settings-daemon.plugins.xsettings hinting slight
gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing rgba
echo "Xft.lcdfilter: lcddefault" | sudo tee ~/.Xresources

# pacmd list-sinks | grep sample and see bitdepth available
# pulseaudio --dump-resample-methods and see resampling available
# Increase quality of Pulse audio sound MAKE SURE your interface can handle s32le 32bit rather than the default 16bit
sudo sed -i "s/; default-sample-format = s16le/default-sample-format = s32le/g" /etc/pulse/daemon.conf
sudo sed -i "s/; resample-method = speex-float-1/resample-method = speex-float-10/g" /etc/pulse/daemon.conf
sudo sed -i "s/; avoid-resampling = false/avoid-resampling = true/g" /etc/pulse/daemon.conf # for pulse 11 only

# Add our current user to the jackuser group
sudo usermod -a -G jackuser "$USERNAME"

# Config Jack assuming jack has created the 95-jack.conf file we are going to overwrite
printf "# Default limits for users of jack-audio-connection-kit\n\n@jackuser - rtprio 98\n@jackuser - memlock unlimited\n\n@pulse-rt - rtprio 20\n@pulse-rt - nice -20" | sudo tee /etc/security/limits.d/95-jack.conf # rewrite the config file

# Create symbolic links for external hard drive folders
ln -s /run/media/david/WD-Red-2TB/Media/Audio ~/Music
ln -s /run/media/david/WD-Red-2TB/Media/Video ~/Videos
ln -s /run/media/david/WD-Red-2TB/Media/Photos ~/Pictures

echo
echo "========================"
echo " REBOOTING IN 1 MINUTE! "
echo "========================"
echo

shutdown -r

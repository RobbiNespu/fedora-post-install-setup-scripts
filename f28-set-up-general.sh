#!/bin/bash

#=======================================================================================
#
#         FILE: f28-set-up-general.sh
#        USAGE: f28-set-up-general.sh
#
#  DESCRIPTION: Post-installation Bash script for Fedora 28 Workstation general use
#      WEBSITE: https://www.elsewebdevelopment.com/
#
# REQUIREMENTS: Fedora 28 installed on your computer
#         BUGS: ---
#        NOTES: After installation you may perform these additional tasks:
#             - Run mpv once then 'printf "profile=gpu-hq\nfullscreen=yes\n" | tee "$HOME/.config/mpv/mpv.conf"' or:
#                                          profile=gpu-hq\nfullscreen=yes\nvideo-sync=display-resample\ninterpolation=yes\ntscale=oversample\n
#             - Install 'Hide Top Bar' extension from Gnome software
#             - Firefox "about:support" what is compositor? If 'basic' open "about:config"
#               find "layers.acceleration.force-enabled" and switch to true, this will
#               force OpenGL acceleration
#             - Update .bash_profile with 'PATH=$PATH:$HOME/.local/bin:$HOME/bin:$HOME/Documents/scripts:$HOME/Documents/scripts/borg-backup'
#             - Install HTTPS everywhere, privacy badger, ublock origin in Firefox/Chromium
#             - Consider "sudo dnf install kernel-tools", "sudo cpupower frequency-set --governor performance"
#             - Files > preferences > views > sort folders before files
#             - Change shotwell import directory format to %Y/%m + rename lower case, import photos from external drive
#             - UMS > un-tick general config > enable external network + check force network on interface is correct network (wlp2s0)
#       AUTHOR: David Else
#      COMPANY: Else Web Development
#      VERSION: 1.0
#=======================================================================================

read -rp "What would you like this computer to be called (hostname)? " hostname
hostnamectl set-hostname "$hostname"

echo "Enabling repositories..."
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || exit 1
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || exit 1

echo "Updating Fedora..."
sudo dnf -y --refresh upgrade

echo "Installing packages..."
sudo dnf -y install libva-intel-driver gstreamer1-vaapi gstreamer1-libav ffmpeg mpv \
    fuse-exfat gnome-tweak-tool gnome-shell-extension-auto-move-windows.noarch gnome-shell-extension-pomodoro \
    java-1.8.0-openjdk keepassx transmission-gtk mkvtoolnix-gui borgbackup syncthing \
    freetype-freeworld lshw mediainfo dolphin-emu mame klavaro jack-audio-connection-kit wine youtube-dl

pip3 install --user mps-youtube

# Add some aliases
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
gsettings set org.gnome.shell.extensions.auto-move-windows application-list "['org.gnome.Nautilus.desktop:2', 'org.gnome.Terminal.desktop:3', 'code.desktop:1', 'firefox.desktop:1']" # for the gnome-shell-extension-auto-move extension
gsettings set org.gnome.shell enabled-extensions "['pomodoro@arun.codito.in', 'auto-move-windows@gnome-shell-extensions.gcampax.github.com']"

# Allow virtual machines that use fusefs to intall properly with SELinux (commented out, hope it now works without this hack)
# sudo setsebool -P virt_use_fusefs 1

# Increase the amount of inotify watchers for live-server and audio
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# Set subpixel hinting for freetype-freeworld
gsettings set org.gnome.settings-daemon.plugins.xsettings hinting slight
gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing rgba
echo "Xft.lcdfilter: lcddefault" | sudo tee ~/.Xresources

# pacmd list-sinks | grep sample and see bit-depth available
# pulseaudio --dump-re-sample-methods and see re-sampling available
sudo sed -i "s/; default-sample-format = s16le/default-sample-format = s32le/g" /etc/pulse/daemon.conf # MAKE SURE your interface can handle s32le 32bit rather than the default 16bit
sudo sed -i "s/; resample-method = speex-float-1/resample-method = speex-float-10/g" /etc/pulse/daemon.conf
sudo sed -i "s/; avoid-resampling = false/avoid-resampling = true/g" /etc/pulse/daemon.conf # for pulse >=11 only

# Add our current user to the jackuser group
sudo usermod -a -G jackuser "$USERNAME"

# Config Jack assuming jack has created the 95-jack.conf file we are going to overwrite
printf "# Default limits for users of jack-audio-connection-kit\n\n@jackuser - rtprio 98\n@jackuser - memlock unlimited\n\n@pulse-rt - rtprio 20\n@pulse-rt - nice -20" | sudo tee /etc/security/limits.d/95-jack.conf # rewrite the config file

# Create symbolic links for external hard drive folders
# ln -s /run/media/david/WD-Red-2TB/Media/Audio ~/Music
# ln -s /run/media/david/WD-Red-2TB/Media/Video ~/Videos
# ln -s /run/media/david/WD-Red-2TB/Media/Photos ~/Pictures

echo
echo "========================="
echo " REBOOTING IN 2 MINUTES! "
echo "========================="
echo

shutdown -r +2

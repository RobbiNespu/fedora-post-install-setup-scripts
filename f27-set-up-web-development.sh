#!/bin/bash

#=======================================================================================
#
#         FILE: XXXXX.sh
#
#        USAGE: XXXXX.sh
#
#  DESCRIPTION: Post-installation Bash script for Fedora Workstation for web development
#      WEBSITE:
#
#      OPTIONS: see function ’usage’ below
# REQUIREMENTS: Fedora installed on your computer
#         BUGS: ---
#        NOTES: After installation you may perform these additional tasks:
#             - Disable drag & drop in Filezilla, run Filezilla once to create the config
#               sudo sed -i "s/Drag and Drop disabled\">0</Drag and Drop disabled\">1</g" ~/.config/filezilla/filezilla.xml
#             - Change phpMyAdmin setting to allow logging into root with no password:
#               sudo gedit /etc/phpMyAdmin/config.inc.php
#               ---------------
#               $cfg['Servers'][$i]['AllowNoPassword'] = TRUE;
#               ---------------
#             - Allow mod-write in Apache, make the following edit
#               sudo gedit /etc/httpd/conf/httpd.conf
#               ---------------
#               # AllowOverride controls what directives may be placed in .htaccess files.
#               # It can be "All", "None", or any combination of the keywords:
#               #   Options FileInfo AuthConfig Limit
#               #
#               AllowOverride All
#               ---------------
#             - For PHP and Fedora 27 these config file changes are vital!
#               sudo gedit /etc/php-fpm.d/www.conf
#               ---------------
#               user = $USERNAME (was apache)
#               listen.acl_users = apache,nginx,$USERNAME
#               ---------------
#       AUTHOR: David Else
#      COMPANY: Else Web Development
#      VERSION: 1.0
#      CREATED: 11-7-17
#     REVISION: 29-11-17
#=======================================================================================

# Enable Microsoft repository for VS Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

echo "Installing packages..."

# ffmpeg-libs is needed for h264 video in firefox, see general install script
sudo dnf -y install php phpmyadmin php-mysqlnd php-opcache mariadb-server sendmail \
    code chromium filezilla nodejs zeal ShellCheck

# Install VS Code extensions
code --install-extension HookyQR.beautify
code --install-extension ban.spellright
code --install-extension christian-kohler.path-intellisense
code --install-extension dbaeumer.vscode-eslint
code --install-extension deerawan.vscode-dash
code --install-extension foxundermoon.shell-format
code --install-extension msjsdiag.debugger-for-chrome
code --install-extension ritwickdey.LiveServer
code --install-extension shinnn.stylelint
code --install-extension timonwong.shellcheck

# Install Node packages
sudo npm install -g npm-check eslint

# install shfmt shell parser onto the system for vs code plugin shell-format
chmod +x shfmt_v2.1.0_linux_amd64
sudo mv shfmt_v2.1.0_linux_amd64 /usr/local/bin/shfmt

# install wordpress cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# Make a directory for websites/apps and add the permissions
mkdir ~/sites
sudo ln -s ~/sites /var/www/html                                 # make symbolic link from the apache web directory to your sites folder
chcon -R unconfined_u:object_r:httpd_sys_rw_content_t:s0 ~/sites # tell SELinux that these files/directories are allowed to be modified by Apache
sudo setsebool -P httpd_can_network_connect 1                    # !! maybe not needed since Fedora 27 updates? !! tell SELinux Apache can connect to the outside network

# Change the "User apache" string in the config file to "User (the username of the current user)". For a development machine, it's more convenient to run Apache as the current user to simplify permissions problems
sudo sed -i "s/User apache/User $USERNAME/g" /etc/httpd/conf/httpd.conf

# Change PHP settings to mirror the production server, and allow more functionality
upload_max_filesize=128M # namesco default setting
post_max_size=128M       # namesco default setting
max_execution_time=60    # namesco default setting, Avada theme recommends 180

for key in upload_max_filesize post_max_size max_execution_time; do
    sudo sed -i "s/^\($key\).*/\1 = $(eval echo \${$key})/" /etc/php.ini
done

sudo systemctl start mariadb.service # start the MYSQL database
sudo mysql_secure_installation       # finish installation of MYSQL to make it secure

sudo setsebool -P httpd_execmem 1 # stop SELinux is preventing php-fpm from using the execmem access on a process

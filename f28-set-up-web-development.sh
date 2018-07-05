#!/bin/bash

#=======================================================================================
#
#         FILE: f28-set-up-web-development.sh
#        USAGE: f28-set-up-web-development.sh
#
#  DESCRIPTION: Post-installation Bash script for Fedora 28 Workstation for web development
#      WEBSITE: https://www.elsewebdevelopment.com/
#
# REQUIREMENTS: Fedora 28 installed on your computer
#         BUGS: ---
#        NOTES: for spellright to work copy Dictionaries to ~/.config/Code/Dictionaries
#               on new system you might need 'ssh-keyscan github.com >> ~/.ssh/known_hosts'
#               ---------------
#       AUTHOR: David Else
#      COMPANY: Else Web Development
#      VERSION: 1.12 (move to Docker for dev environment)
#=======================================================================================

if [ ! -f ./shfmt_v2.3.0_linux_amd64 ]; then
    echo "shfmt_v2.3.0_linux_amd64 File not found!" && exit 1
fi

# Enable Microsoft repository for VS Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || exit 1
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

echo "Installing packages..."

# ffmpeg-libs is needed for h264 video in Firefox, see general install script, maybe add python3-tkinter for GUI in Python
sudo dnf -y install docker docker-compose code chromium chromium-libs-media-freeworld nodejs zeal ShellCheck php php-json

# Install VS Code extensions
code --install-extension WallabyJs.quokka-vscode
code --install-extension ban.spellright
code --install-extension dbaeumer.vscode-eslint
code --install-extension deerawan.vscode-dash
code --install-extension esbenp.prettier-vscode
code --install-extension foxundermoon.shell-format
code --install-extension mkaufman.HTMLHint
code --install-extension msjsdiag.debugger-for-chrome
code --install-extension ritwickdey.LiveServer
code --install-extension shinnn.stylelint
code --install-extension timonwong.shellcheck

# Install global Node packages
sudo npm install -g npm-check eslint

# Setup WP-Cli - you must have a $HOME/bin directory in the PATH
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar ~/bin/wp # move it to new folder and rename it 'wp'
wp --info                    # show WP-Cli info to show it's working

# Install shfmt shell formatter from current directory onto the system for VS Code plugin shell-format
# Binary available from https://github.com/mvdan/sh/releases
chmod +x shfmt_v2.3.0_linux_amd64
sudo mv shfmt_v2.3.0_linux_amd64 /usr/local/bin/shfmt

# Make a directory for websites/apps
mkdir "$HOME/sites"

# Set git global values, you can still change them per project without the --global
git config --global user.email "david@Gigabot"
git config --global user.name "David"

# VS Code settings
cat >"$HOME/.config/Code/User/settings.json" <<EOL
// Place your settings in this file to overwrite the default settings
// Place your settings in this file to overwrite the default settings
{
    // VS Code 1.25.0 general settings
    "editor.renderWhitespace": "all",
    "editor.dragAndDrop": false,
    "editor.formatOnSave": true,
    "editor.minimap.enabled": true,
    "editor.detectIndentation": false,
    "workbench.editor.enablePreview": false,
    "workbench.activityBar.visible": false,
    "window.menuBarVisibility": "toggle",
    "window.titleBarStyle": "custom",
    "zenMode.fullScreen": false,
    "zenMode.centerLayout": false,
    "telemetry.enableTelemetry": false,
    "javascript.showUnused": false,
    "explorer.sortOrder": "modified",
    "git.autofetch": true,
    "git.enableSmartCommit": true,
    "php.validate.executablePath": "/usr/bin/php",
    "extensions.showRecommendationsOnlyOnDemand": true,
    "css.validate": false, // as we are using stylelint
    "less.validate": false, // as we are using stylelint
    "scss.validate": false, // as we are using stylelint
    "[javascript]": {
        "editor.tabSize": 2
    },
    "[json]": {
        "editor.tabSize": 2
    },
    "[css]": {
        "editor.tabSize": 2
    },
    "[html]": {
        "editor.tabSize": 2
    },
    // Shell Format extension
    "shellformat.flag": "-i 4",
    // Dash extension
    "dash.docset.javascript": [
        "javascript",
        "mocha",
        "chai",
        "svg"
    ],
    // Live Server extension
    "liveServer.settings.donotShowInfoMsg": true,
    "liveServer.settings.ChromeDebuggingAttachment": true,
    "liveServer.settings.ignoreFiles": [
        ".vscode/**",
        // "src/**",
    ],
    "liveServer.settings.AdvanceCustomBrowserCmdLine": "/usr/bin/chromium-browser --remote-debugging-port=9222",
    // Spell Right extension
    "spellright.language": "English (British)",
    // Prettier formatting extension
    "prettier.singleQuote": true,
    "prettier.trailingComma": "all",
    // HTML formatting
    "html.format.endWithNewline": true,
    "html.format.wrapLineLength": 80,
    "workbench.statusBar.feedback.visible": false,
    "spellright.documentTypes": [
        "markdown",
        "latex",
        "plaintext"
    ],
    "eslint.validate": [
        "javascript",
        "javascriptreact",
        "html"
    ]
}
EOL

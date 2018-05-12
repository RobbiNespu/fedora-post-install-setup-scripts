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
#        NOTES:
#               ---------------
#       AUTHOR: David Else
#      COMPANY: Else Web Development
#      VERSION: 1.1 (move to Docker for dev environment)
#=======================================================================================

if [ ! -f ./shfmt_v2.3.0_linux_amd64 ]; then
    echo "shfmt_v2.3.0_linux_amd64 File not found!"
fi

# Enable Microsoft repository for VS Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || exit 1
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

echo "Installing packages..."

# ffmpeg-libs is needed for h264 video in Firefox, see general install script, maybe add python3-tkinter for GUI in Python
sudo dnf -y install docker docker-compose code chromium nodejs zeal ShellCheck

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

# Install shfmt shell formatter from current directory onto the system for VS Code plugin shell-format
# Binary available from https://github.com/mvdan/sh/releases
chmod +x shfmt_v2.3.0_linux_amd64
sudo mv shfmt_v2.3.0_linux_amd64 /usr/local/bin/shfmt

# Make a directory for websites/apps
mkdir ~/sites

# VS Code settings
cat >"$HOME/.config/Code/User/settings.json" <<EOL
// Place your settings in this file to overwrite the default settings
{
    // VS Code general settings
    "editor.renderWhitespace": "all",
    "editor.dragAndDrop": false,
    "editor.formatOnSave": true,
    "workbench.editor.enablePreview": false,
    "workbench.activityBar.visible": false,
    "window.menuBarVisibility": "toggle",
    "telemetry.enableTelemetry": false,
    "zenMode.fullScreen": false,
    "explorer.sortOrder": "modified",
    "git.autofetch": true,
    "php.validate.executablePath": "/usr/bin/php",
    "extensions.showRecommendationsOnlyOnDemand": true,
    "css.validate": false, // as we are using stylelint
    "less.validate": false, // as we are using stylelint
    "scss.validate": false, // as we are using stylelint
    "editor.detectIndentation": false,
    "[javascript]": {
        "editor.tabSize": 2
    },
    "[json]": {
        "editor.tabSize": 2
    },
    "[css]": {
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
        "dist/bundle.css",
        "**/*.scss",
        "**/*.sass"
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
    ]
}
EOL

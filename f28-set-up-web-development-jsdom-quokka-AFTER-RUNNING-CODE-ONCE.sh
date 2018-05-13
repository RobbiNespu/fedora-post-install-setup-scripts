#!/bin/bash

# Install jsdom-quokka-plugin for quokka and set it to use the project's root directory index.html
cd "$HOME/.quokka" || exit
npm init
npm install jsdom-quokka-plugin
cat >"$HOME/.quokka/config.json" <<EOL
{"plugins":["jsdom-quokka-plugin"],"jsdom":{"config":{"file":"index.html"}},"pro":false}
EOL

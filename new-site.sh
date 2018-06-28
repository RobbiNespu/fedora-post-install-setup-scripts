#!/bin/bash

# the root directory for the project to be installed in
projectroot=$HOME/sites

# function to modify the HTML template
libraries() {
    if [ "$1" == "vue" ]; then
        div='<div id="app">{{ message }}</div>'
        link='<script src="./vendor/vue.js"></script>'
        indexhtml=$(printf "$tpl" "$div" "$link")
    else
        indexhtml=$(printf "$tpl")
    fi
}

#################################################
#                                               #
# common templates always installed             #
#                                               #
#################################################

#################################################
# index.html (modified by libraries function)   #
#################################################
read -d '' tpl <<_EOF_
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <link rel="stylesheet" href="./dist/bundle.css">
  <title>Document</title>
</head>

<body>
%s
</body>

%s
<script src="./dist/bundle.js"></script>

</html>
_EOF_

#################################################
# .gitignore                                    #
#################################################
gitnore=$(
    cat <<EOF
node_modules/*
EOF
)

#################################################
# rollup.config.js                              #
#################################################
rollupconfig=$(
    cat <<EOF
import postcss from 'rollup-plugin-postcss';

export default {
  input: 'src/main.js',
  output: {
    file: 'dist/bundle.js',
    format: 'iife',
    sourcemap: true,
  },
  plugins: [
    postcss({
      plugins: [],
      sourceMap: true,
      extract: true,
      // minimize: true,
    }),
  ],
};
EOF
)

#################################################
# tests.js                                      #
#################################################
test=$(
    cat <<EOF
/* eslint-disable */
import app from '../src/app.js';

const assert = chai.assert;
EOF
)

#################################################
# test-runner.html                              #
#################################################
testrunner=$(
    cat <<EOF
<!DOCTYPE html>
<html>

<head>
  <title>Mocha Tests</title>
  <link rel="stylesheet" href="node_modules/mocha/mocha.css">
</head>

<body>
  <!-- hide the actual HTML that is needed for the tests, if any is needed -->
  <div id="app" style="display:none;"></div>

  <!-- create element for the test results and load the testing programs -->
  <div id="mocha"></div>

  <script src="node_modules/mocha/mocha.js"></script>
  <script src="node_modules/chai/chai.js"></script>

  <script>
    mocha.setup('bdd')
  </script>

  <!-- bundled js to test -->
  <!-- <script type="module" src="./src/main.js"></script> -->

  <!-- the test file containing the tests -->
  <script type="module" src="./test/tests.js"></script>

  <script type="module">
    mocha.setup({ globals: ['__VUE_DEVTOOLS_TOAST__'] });
    mocha.checkLeaks();
    mocha.run();
  </script>
</body>

</html>
EOF
)

#################################################
# main.js                                       #
#################################################
mainjs=$(
    cat <<EOF
import '../src/app.js';
EOF
)

#################################################
# app.js                                        #
#################################################
appjs=$(
    cat <<EOF
import '../src/main.css';
EOF
)

#################################################
#                                               #
# vue templates not always installed            #
#                                               #
#################################################

#################################################
# app.js                                        #
#################################################
appjsvue=$(
    cat <<EOF
/* global Vue */

import '../src/main.css';

export default new Vue({
  el: '#app',
  data() {
    return {
      message: 'Hello Vue!',
    };
  },
});
EOF
)

#################################################
# main script begins                            #
#################################################

# check you have npm installed before proceeding
hash npm 2>/dev/null || {
    echo >&2 "You need to install NPM to use this script"
    exit 1
}

# ask user for project directory name and create it in the project root folder
clear
cd "$projectroot" || exit
read -rp "Enter name for new website (will be converted to lowercase with spaces replaced with -): " sitename
sitename=${sitename,,}    # make lower-case for compatibility across servers
sitename=${sitename// /-} # use in-line shell string replacement to remove spaces and replace with -
mkdir "$sitename" || exit
cd "$sitename" || exit

# create common files and folders
mkdir src dist tests vendor assets
touch README.md src/main.css
echo "$gitnore" >".gitignore"
echo "$test" >"tests/tests.js"
echo "$testrunner" >"test-runner.html"
echo "$mainjs" >"src/main.js"
echo "$rollupconfig" >"rollup.config.js"

# npm init and install default packages
npm init --yes
npm install --save-dev rollup rollup-plugin-postcss mocha chai

#################################################
# install vue optionally and exit               #
#################################################
echo
read -p "Install Vue? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm install vue
    cp node_modules/vue/dist/vue.js vendor
    mkdir src/components
    libraries "vue"
    echo "$indexhtml" >"index.html"
    echo "$appjsvue" >"src/app.js"

    git init
    exit
fi

# if vue was not installed we write other files
libraries
echo "$indexhtml" >"index.html"
echo "$appjs" >"src/app.js"

git init

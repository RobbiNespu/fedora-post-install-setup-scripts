#!/bin/bash

# the root directory for the project to be installed in
projectroot=$HOME/sites

# function to modify the HTML template
libraries() {
    if [ "$1" == "vue" ]; then
        div='  <div id="app">{{ message }}</div>'
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

packagejson=$(
    cat <<EOF
{
  "name": "app",
  "version": "1.0.0",
  "description": "",
  "main": "src/main.js",
  "scripts": {
    "watch": "watch --interval=0.5 'npm run build-js' src/js & watch --interval=0.5 'npm run copy-css' src/css",
    "build-js": "rollup --format=iife --file=dist/bundle.js -- src/js/main.js",
    "build-css": "purgecss --css src/css/*.css --content index.html src/js/*.js --out dist",
    "copy-css": "cp src/css/*.css dist",
    "update-vendor-dir-vue-copy": "cp node_modules/vue/dist/vue.js vendor"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
EOF
)

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
  <link rel="stylesheet" href="./dist/main.css">
  <title>Document</title>
</head>

<body>
%s
</body>

%s
<script src="./dist/bundle.js"></script>

<!-- floating window for tests, DELETE FOR PRODUCTION -->
<iframe id="tests-dialog" style="position:sticky;bottom:0;border-width: 2px 0 0;width:100%%;height:345px;background:white;"
  src="http://127.0.0.1:5500/test-runner.html"></iframe>
<button onclick="toggleTests()" style="position:sticky; bottom: 3px;left:3px;">T</button>
<script>
  function toggleTests() {
    const x = document.getElementById('tests-dialog');
    if (x.style.display === 'none') {
      x.style.display = 'block';
    } else {
      x.style.display = 'none';
    }
  }
</script>
<!-- floating window for tests, DELETE FOR PRODUCTION -->

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
# tests.js                                      #
#################################################
test=$(
    cat <<EOF
/* eslint-disable */
import app from '../src/js/app.js';

const assert = chai.assert;

describe('Basic Mocha String Test', function() {
  it('should return number of charachters in a string', function() {
    assert.equal(app.stringVariable.length, 5);
  });
});
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
  <!-- <script type="module" src="./src/js/main.js"></script> -->

  <!-- the test file containing the tests -->
  <script type="module" src="./tests/tests.js"></script>

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
import '../js/app.js';
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
mkdir src src/js src/css dist tests vendor assets
wget -P src/css https://cdn.jsdelivr.net/npm/tailwindcss/dist/tailwind.min.css
touch README.md src/css/main.css src/js/app.js
echo "$packagejson" >"package.json"
echo "$gitnore" >".gitignore"
echo "$test" >"tests/tests.js"
echo "$testrunner" >"test-runner.html"
echo "$mainjs" >"src/js/main.js"

# npm init and install default packages
npm install --save-dev rollup watch mocha chai

#################################################
# install Purgecss optionally                   #
#################################################
echo
read -p "Install Purgecss? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm install --save-dev purgecss
fi

#################################################
# install vue optionally and exit               #
#################################################
echo
read -p "Install Vue? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm install vue
    cp node_modules/vue/dist/vue.js vendor
    mkdir src/js/components
    libraries "vue"
    echo "$indexhtml" >"index.html"
    echo "$appjsvue" >"src/js/app.js"
else
    libraries
    echo "$indexhtml" >"index.html"
fi

git init
code .

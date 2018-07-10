#!/bin/bash

# check you have npm installed before proceeding
hash npm 2>/dev/null || {
    echo >&2 "You need to install NPM to use this script" && exit 1
}

# define the root directory for the project to be installed in
projectroot=$HOME/sites

# ask user for project directory name and create it in the project root folder
clear
cd "$projectroot" || exit
read -rp "Enter name for new website (will be converted to lowercase with spaces replaced with -): " sitename
sitename=${sitename,,}    # make lower-case for compatibility across servers
sitename=${sitename// /-} # use in-line shell string replacement to remove spaces and replace with -
mkdir "$sitename" || exit
cd "$sitename" || exit

#################################################
# create common files and folders               #
#################################################

# .gitignore template ###########################
gitnore=$(
    cat <<EOF
node_modules/*
EOF
)

mkdir src dist test vendor assets
touch README.md
echo "$gitnore" >".gitignore"

wget -P src https://cdn.jsdelivr.net/npm/tailwindcss/dist/tailwind.min.css || exit 1
mv src/tailwind.min.css src/main.css

echo
read -p "Install Vue? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    #################################################
    # install and setup vue                         #
    #################################################

    #  vue package.json template ####################
    vue_package_json=$(
        cat <<EOF
{
  "name": "app",
  "version": "1.0.0",
  "description": "",
  "main": "src/main.js",
  "scripts": {
    "global-install": "npm install -g mocha jsdom jsdom-global",
    "test": "mocha --reporter min --require esm --require jsdom-global/register -b",
    "test-watch": "mocha --watch --reporter min --require esm --require jsdom-global/register -b",
    "build": "rollup --format=iife --file=dist/bundle.js -- src/main.js && purgecss --css src/main.css --content index.html src/**/*.js --out dist",
    "update-vendor-dir-vue-copy": "cp node_modules/vue/dist/vue.js vendor"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "@vue/test-utils": "^1.0.0-beta.20",
    "esm": "^3.0.64",
    "purgecss": "^1.0.1",
    "rollup": "^0.62.0",
    "vue-template-compiler": "^2.5.16"
  },
  "dependencies": {
    "vue": "^2.5.16"
  }
}
EOF
    )

    #  vue index.html template ######################
    vue_index_html=$(
        cat <<EOF
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <title>Vue App</title>
  <link href="src/main.css" rel="stylesheet">
  <!-- <link href="dist/main.css" rel="stylesheet"> -->
  <script src="vendor/vue.js"></script>
  <script src="src/main.js" type="module"></script>
</head>

<body>
  <div id="app"></div>
</body>

<!-- <script src="dist/bundle.js"></script> -->

</html>
EOF
    )

    #  vue test template ######################
    vue_test=$(
        cat <<EOF
import { strictEqual, deepStrictEqual } from 'assert';
import { mount } from '@vue/test-utils';
import App from '../src/App.js';

describe('App', () => {
  const wrapper = mount(App);
  const testData = 2;

  it('should return 3 when it has a passed parameter of 2', () => {
    const actual = wrapper.vm.test(testData);
    const expected = 3;
    assert.strictEqual(actual, expected);
  });
});
EOF
    )

    #  vue main template ######################
    vue_main=$(
        cat <<EOF
/* global Vue */
import App from './App.js';

new Vue({
  render: h => h(App),
}).\$mount('#app');
EOF
    )

    #  vue app template ######################
    vue_app=$(
        cat <<EOF
// import UserList from './components/UserList.js';

export default {
  name: 'App',
  // components: {
  //   UserList,
  // },
  template: /* html */ \`
  <p class="text-green">Vue and tailwind are working OK!</p>
  \`,
  methods: {
    test(x) {
      return x + 1;
    },
  },
};
EOF
    )

    mkdir src/components
    echo "$vue_package_json" >"package.json"
    echo "$vue_index_html" >"index.html"
    echo "$vue_test" >"test/App-test.js"
    echo "$vue_main" >"src/main.js"
    echo "$vue_app" >"src/App.js"

    npm install
    cp node_modules/vue/dist/vue.js vendor

else
    #################################################
    # install and setup standard template           #
    #################################################

    #  package.json template ####################
    package_json=$(
        cat <<EOF
{
  "name": "app",
  "version": "1.0.0",
  "description": "",
  "main": "src/main.js",
  "scripts": {
    "global-install": "npm install -g mocha jsdom jsdom-global",
    "test": "mocha --reporter min --require esm --require jsdom-global/register -b",
    "test-watch": "mocha --watch --reporter min --require esm --require jsdom-global/register -b",
    "build": "rollup --format=iife --file=dist/bundle.js -- src/main.js && purgecss --css src/main.css --content index.html src/**/*.js --out dist"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "esm": "^3.0.64",
    "purgecss": "^1.0.1",
    "rollup": "^0.62.0"
  }
}
EOF
    )

    #  index.html template ######################
    index_html=$(
        cat <<EOF
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <title>App</title>
  <link href="src/main.css" rel="stylesheet">
  <!-- <link href="dist/main.css" rel="stylesheet"> -->
  <script src="src/main.js" type="module"></script>
</head>

<body>
  <div id="app"></div>
</body>

<!-- <script src="dist/bundle.js"></script> -->

</html>
EOF
    )

    #  test template ######################
    test=$(
        cat <<EOF
import { strictEqual, deepStrictEqual } from 'assert';
import App from '../src/app.js';

document.body.innerHTML = '<div id="app"></div>';

describe('App', () => {
  const testData = 2;

  it('should return 3 when it has a passed parameter of 2', () => {
    const actual = App.test(testData);
    const expected = 3;
    assert.strictEqual(actual, expected);
  });
});
EOF
    )

    mkdir src/modules
    touch src/main.js src/app.js
    echo "$package_json" >"package.json"
    echo "$index_html" >"index.html"
    echo "$test" >"test/app-test.js"
    npm install

fi

code .

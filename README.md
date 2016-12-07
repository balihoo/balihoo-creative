Balihoo Web Designer Toolkit 
============================

`balihoo-creative` allows web and interactive designers to build customizable templates
on their own workstation, using their favorite editors and compile tools. It integrates
with Balihoo's online resources like Form-Builder & BLIP to make template design and
maintenance a seemless, painless experience.

## Version
0.2.1

## Installation
  Make sure you have a recent version of node and npm installed and
  then run:
  ```shellscript
  sudo npm -g install balihoo-creative
  ```
  If npm is installed as root then you may have to run it using sudo.

## Updating
  To update to the most recent version run:
  ```shellscript
  sudo npm -g update balihoo-creative
  ```

## Usage

  The app contains its own extensive documentation and tutorial. To view the docs
  and tutorial: first, install the app, create an empty directory and run the app
  within that directory.
  ```shellscript
  mkdir /tmp/project
  cd /tmp/project
  balihoo-creative
  ```
  Running the app in an empty directory will generate the tutorial project in that
  directory, run the web server, and open your browser to the *Getting Started*
  tutorial page.

## Contribute

  To contribute to this project, first fork it on github. Then, clone your fork to
  your workstation.
  ```shellscript
  git clone https://github.com/balihoo/balihoo-creative.git
  cd balihoo-creative
  ```
  
  You will be testing the in-development code instead of the published package, so you should NOT have the tool installed globally.  If it is, you can uninstall it with
  ```shellscript
  sudo npm -g uninstall balihoo-creative
  ```

  Then, run npm install and link the binary to your development copy.
  ```shellscript
  npm install
  npm link
  ```

  This project is built using coffeescript that is transpiled to javascript.
  Make sure that you have coffeescript installed globally.
  ```shellscript
  npm install -g coffee-script
  ```
  While developing you should run the following from the root of your project.
  This will watch the source files and compile them as they change.
  ```shellscript
  coffee -o lib/ -cw src/
  ```

## License

The MIT License (MIT)
=====================

Copyright (c) 2014 Balihoo, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


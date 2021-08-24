#!/bin/sh
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
nvm install lts/dubnium
nvm use lts/dubnium
npm install gitbook-cli
gitbook install
# apt install calibre

#!/bin/bash
# Install Hack Nerd Font
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip
unzip Hack.zip
sudo mkdir /usr/share/fonts/nerd
sudo mv *.ttf * /usr/share/fonts/nerd/
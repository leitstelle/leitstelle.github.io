#!/bin/bash
################################################################################
# Check before you run this. 
# NO WARRANTY!!!
# Run as root.
################################################################################

# DebianMultimedia - http://www.deb-multimedia.org/
gpg --keyserver pgp.mit.edu --recv-keys 07dc563d1f41b907
gpg --armor --export 07dc563d1f41b907 | apt-key add -

# DebianMozilla - http://mozilla.debian.net/
gpg --keyserver pgp.mit.edu --recv-keys 85A3D26506C4AE2A
gpg --armor --export 85A3D26506C4AE2A | apt-key add -

# VLC - http://download.videolan.org/
wget -O - http://download.videolan.org/pub/debian/videolan-apt.asc | apt-key add -

# NeuroDebian - http://neurodebian.ovgu.de/
gpg --keyserver pgp.mit.edu --recv-keys A5D32F012649A5A9
gpg --armor --export A5D32F012649A5A9 | apt-key add -

# Google - http://dl.google.com/
gpg --keyserver pgp.mit.edu --recv-keys A040830F7FAC5991
gpg --armor --export A040830F7FAC5991 | apt-key add -


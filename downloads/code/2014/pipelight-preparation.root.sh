#!/usr/bin/env bash

# Script for GNU/Linux Debian Jessie (Testing).

# Run this script with root rights.
# Some root things have to be done.

# Create new user
adduser film

# Add user film to group video
adduser film video

wine_compholio_dep=('lib32-fontconfig'
           'lib32-libxcursor'
           'lib32-libxrandr'
           'lib32-libxdamage'
           'lib32-libxi'
           'lib32-gettext'
           'lib32-glu'
           'lib32-libsm'
           'lib32-gcc-libs'
           'lib32-attr'
           'desktop-file-utils')

wine_compholio_dev=('autoconf'
	'ncurses'
	'bison'
	'perl'
	'fontforge'
	'flex'
	'prelink'
	'gcc-multilib>=4.5.0-2'
	'lib32-giflib'
	'lib32-libpng'
	'lib32-gnutls'
	'lib32-libxinerama'
	'lib32-libxcomposite'
	'lib32-libxmu'
	'lib32-libxxf86vm'
	'lib32-libxml2'
	'lib32-libldap'
	'lib32-lcms'
	'lib32-mpg123'
	'lib32-openal'
	'lib32-v4l-utils'
	'lib32-alsa-lib'
	'lib32-mesa'
	'lib32-libgl'
	'lib32-libcl'
	'attr'
	'samba'
	'pulseaudio'
	'opencl-headers')

# Application dependencies. 
# (Instead of 'zenity' you can use: 'kde-baseapps-bin' AND 'qdbus'.)
pipelight_dep=('libc6' 
	'libgcc1' 
	'libstdc++6' 
	'libx11-6' 
	'debconf' 
	'mesa-utils' 
	'ttf-mscorefonts-installer' 
	'wget' 
	'zenity'  
	'bash' 
	'unzip' 
	'cabextract' 
	'gnupg')

# Development dependencies.
pipelight_dev=('libc6-dev' 
	'libx11-dev'
	'mingw-w64' 
	'g++-mingw-w64' 
	'make' 
	'g++' 
	'sed'
)


aptitude install ${wine_compholio_dep} ${wine_compholio_dev} ${pipelight_dep} ${pipelight_dev}


# XATTR support
# XATTR is for ext3 and ext4 enabled out of the box.
#
# # Install the attr package (example for Ubuntu/Debian):
# aptitude install attr
# # Check XATTR
# touch ~/.xattr_test && setfattr -n 'user.testAttr' -v 'attribute value' ~/.xattr_test &> /dev/null; getfattr ~/.xattr_test 2>&1 | grep -q user.testAttr && echo 'It works!' || echo 'No workie!'; rm ~/.xattr_test &> /dev/null

# Root things are done.

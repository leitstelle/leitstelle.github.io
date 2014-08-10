################################################################################
# Maintainer  : Frank Zisko
# Contributor : leitstelle.salzkraftwerk.org
# Web: http://pipelight.net/cms/page-wine.html
################################################################################

### Dependencies ### ###########################################################
aptitude install debootstrap

### VARIABLES ### ##############################################################
USERNAME=$(id -u -n)
INSTALL_ROOT=/home/${USERNAME}/.0
#INSTALL_ROOT=${HOME}/.0
#INSTALL_ROOT=/localdata

WINE_VERSION="1.7.19"
WINE_NAME="wine-compholio"
WINE_DOWNLOAD_NAME=wine-${WINE_VERSION}
WINE_DOWNLOAD_FILE=${WINE_DOWNLOAD_NAME}.tar.bz2
WINE_UNPACK_NAME=${WINE_DOWNLOAD_NAME}
WINE_BUILDDIR_NAME="wine-compholio"
WINE_SOURCE_DIR=${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_VERSION}
WINE_INSTALL_DIR=${INSTALL_ROOT}/opt/${WINE_NAME}/${WINE_VERSION}
#
WINE_PATCH_PACK=v${WINE_VERSION}-1.tar.gz

#PIPELIGHT_VERSION="0.2.7"
PIPELIGHT_VERSION="git"
PIPELIGHT_NAME="pipelight"
PIPELIGHT_DOWNLOAD_NAME=pipelight-${PIPELIGHT_VERSION}
PIPELIGHT_DOWNLOAD_FILE=${PIPELIGHT_DOWNLOAD_NAME}.tar.bz2
PIPELIGHT_UNPACK_NAME=${PIPELIGHT_DOWNLOAD_NAME}
PIPELIGHT_BUILDDIR_NAME="pipelight"
PIPELIGHT_SOURCE_DIR=${INSTALL_ROOT}/src/${PIPELIGHT_NAME}/${PIPELIGHT_VERSION}
PIPELIGHT_INSTALL_DIR=${INSTALL_ROOT}/opt/${PIPELIGHT_NAME}/${PIPELIGHT_VERSION}
#
PIPELIGHT_LIB_DIR=${PIPELIGHT_INSTALL_DIR}/lib/pipelight
PIPELIGHT_BIN_DIR=${PIPELIGHT_INSTALL_DIR}/bin


### PATHS ### ##################################################################
mkdir -p ${INSTALL_ROOT}
mkdir -p ${INSTALL_ROOT}/src/${WINE_NAME}
mkdir -p ${INSTALL_ROOT}/opt/${WINE_NAME}
mkdir -p ${INSTALL_ROOT}/src/${PIPELIGHT_NAME}
mkdir -p ${INSTALL_ROOT}/opt/${PIPELIGHT_NAME}


#### DOWNLOAD ### ###############################################################
#cd ${INSTALL_ROOT}

#### Wine compholio
#wget -O ${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_DOWNLOAD_FILE} http://prdownloads.sourceforge.net/wine/${WINE_DOWNLOAD_FILE}
##git clone git://source.winehq.org/git/wine-git src/${WINE_NAME}/git
##wget http://prdownloads.sourceforge.net/wine/${WINE_DOWNLOAD_FILE}.sign
##wine-compholio mirror: wget -O ${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_DOWNLOAD_FILE} https://down.salzkraftwerk.org/wine/${WINE_DOWNLOAD_FILE}

#### Wine compholio patches
#wget -O ${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_PATCH_PACK} https://github.com/compholio/wine-compholio-daily/archive/${WINE_PATCH_PACK}
##Patch mirror: wget -O ${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_PATCH_PACK} https://down.salzkraftwerk.org/wine/${WINE_PATCH_PACK}

#### Pipelight
#git clone https://bitbucket.org/mmueller2012/pipelight.git src/${PIPELIGHT_NAME}/git
##Pipelight mirror: git clone https://git.salzkraftwerk.org/pipelight.git src/${PIPELIGHT_NAME}/git


#### WINE ### ###################################################################
#cd ${INSTALL_ROOT}/src/${WINE_NAME}
#tar -xjf ${WINE_DOWNLOAD_FILE}
#mv ${WINE_UNPACK_NAME} ${WINE_VERSION}


# Unpack patches into wine source dir.
#cd ${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_VERSION}
cd ${WINE_SOURCE_DIR}
tar xzf ../${WINE_PATCH_PACK} --strip-components 1

# Apply the patches
make -C ./patches DESTDIR=${WINE_SOURCE_DIR} install
#patch -p1 < ../000X-YYYYYYY.patch


# These additional CPPFLAGS solve FS#27662 and FS#34195
export CFLAGS="$CFLAGS -DHAVE_ATTR_XATTR_H=1"
export CPPFLAGS="${CPPFLAGS/-D_FORTIFY_SOURCE=2/} -D_FORTIFY_SOURCE=0"

export MAKEFLAGS="-j4"

# Update configure script. 
autoreconf

# Configure wine.
  ./configure \
    --prefix=${WINE_INSTALL_DIR} \
    --with-xattr
    #--with-x \
    #--without-gstreamer \
    #--enable-win64
    # Gstreamer was disabled for FS#33655

# Build.
    #make -j depend
    #make -j
    #make install

###else
###  exit
###fi




#### PIPELIGHT ### ##############################################################
##!/bin/bash
#USER_HOME=${HOME}
#${INSTALL_ROOT} 		USER_INSTALL_DIR=${USER_HOME}/.local/usr
#PIPELIGHT_INSTALL_DIR   	USER_PIPELIGHT_LIB_DIR=${USER_INSTALL_DIR}/lib/pipelight

## Configure pipelight and build it.
#cd ${PIPELIGHT_SOURCE_DIR}
#./configure --prefix=${PIPELIGHT_INSTALL_DIR}  --moz-plugin-path=${HOME}/.mozilla/plugins/
## --wine-path="${WINE_INSTALL_DIR}/bin/wine" --gcc-runtime-dlls="/lib/x86_64-linux-gnu/"

#make -j
#make install

## Postinstall. Copy 'libpipelight.so' to available plugins. Yes, this works like that.
#cp ${PIPELIGHT_LIB_DIR}/libpipelight.so ${PIPELIGHT_LIB_DIR}/libpipelight-flash.so
#cp ${PIPELIGHT_LIB_DIR}/libpipelight.so ${PIPELIGHT_LIB_DIR}/libpipelight-silverlight4.so
#cp ${PIPELIGHT_LIB_DIR}/libpipelight.so ${PIPELIGHT_LIB_DIR}/libpipelight-silverlight5.0.so
#cp ${PIPELIGHT_LIB_DIR}/libpipelight.so ${PIPELIGHT_LIB_DIR}/libpipelight-silverlight5.1.so
#cp ${PIPELIGHT_LIB_DIR}/libpipelight.so ${PIPELIGHT_LIB_DIR}/libpipelight-unity3d.so
#cp ${PIPELIGHT_LIB_DIR}/libpipelight.so ${PIPELIGHT_LIB_DIR}/libpipelight-widevine.so


## Need '$HOME/bin' in PATH. If this is not configured, configure it. ;-)
## mkdir -p ${HOME}/bin
## cat <<EOF >> ${USER_HOME}/.profile
## cat <<EOF >> ${USER_HOME}/.bash_profile
## # if running bash
## if [ -n "$BASH_VERSION" ]; then
##     # include .bashrc if it exists
##     if [ -f "$HOME/.bashrc" ]; then
##         . "$HOME/.bashrc
##     fi
## fi
## # set PATH so it includes user's private bin if it exists
## if [ -d "$HOME/bin" ] ; then
##     PATH="$HOME/bin:$PATH"
## fi
## EOF
## bash -l
## TODO: Write small bash profile help.

## Postinstall. Create link from '~/bin/pipelight-plugin' to '~/.locale/usr/bin/pipelight-plugin'.
#ln -s ${PIPELIGHT_INSTALL_DIR}/bin/pipelight-plugin ${HOME}/bin/pipelight-plugin

## Start Browser. On first run firefox detects a new plugin.
## This initalize a new wine bottle and install the plugins.
#pipelight-plugin --enable silverlight

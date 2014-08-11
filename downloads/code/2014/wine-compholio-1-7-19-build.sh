################################################################################
# Maintainer  : Frank Zisko
# Contributor : leitstelle.salzkraftwerk.org
# Web: http://pipelight.net/cms/page-wine.html
################################################################################


### VARIABLES ### ##############################################################
USERNAME=$(id -u -n)
#INSTALL_ROOT=${USERNAME}/.local/usr
INSTALL_ROOT=/localdata

WINE_VERSION="1.7.19"
WINE_NAME="wine-compholio"
WINE_DOWNLOAD_NAME=wine-${WINE_VERSION}
WINE_DOWNLOAD_FILE=${WINE_DOWNLOAD_NAME}.tar.bz2
WINE_PATCH_PACK=v${WINE_VERSION}-1.tar.gz
WINE_UNPACK_NAME=${WINE_DOWNLOAD_NAME}
WINE_BUILDDIR_NAME="wine-compholio"
WINE_SOURCE_DIR=${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_VERSION}
WINE_INSTALL_DIR=${INSTALL_ROOT}/opt/${WINE_NAME}/${WINE_VERSION}


PIPELIGHT_VERSION="0.2.7"
PIPELIGHT_NAME="pipelight"
PIPELIGHT_DOWNLOAD_NAME=pipelight-${PIPELIGHT_VERSION}
PIPELIGHT_DOWNLOAD_FILE=${PIPELIGHT_DOWNLOAD_NAME}.tar.bz2
PIPELIGHT_DOWNLOAD_FPRINT=""
PIPELIGHT_BUILDDIR_NAME="pipelight"
PIPELIGHT_SOURCE_DIR=${INSTALL_ROOT}/src/${PIPELIGHT_NAME}/${WINE_VERSION}
PIPELIGHT_INSTALL_DIR=${INSTALL_ROOT}/opt/${PIPELIGHT_NAME}/${WINE_VERSION}


### PATHS ### ##################################################################
mkdir -p ${INSTALL_ROOT}
mkdir -p ${WINE_SOURCE_DIR}
mkdir -p ${WINE_INSTALL_DIR}
mkdir -p ${PIPELIGHT_SOURCE_DIR}
mkdir -p ${PIPELIGHT_INSTALL_DIR}

### DOWNLOAD ### ###############################################################
cd ${INSTALL_ROOT}
wget -O ${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_DOWNLOAD_FILE} http://prdownloads.sourceforge.net/wine/${WINE_DOWNLOAD_FILE}
#wget http://prdownloads.sourceforge.net/wine/${WINE_DOWNLOAD_FILE}.sign
wget -O ${INSTALL_ROOT}/src/${WINE_NAME}/${WINE_PATCH_PACK} https://github.com/compholio/wine-compholio-daily/archive/${WINE_PATCH_PACK}
git clone https://bitbucket.org/mmueller2012/pipelight.git src/${PIPELIGHT_NAME}/git

### WINE ### ###################################################################
cd ${INSTALL_ROOT}/src/${WINE_NAME}


tar -xjf ${WINE_DOWNLOAD_FILE}
mv ${WINE_UNPACK_NAME} ${WINE_VERSION}
cd ${WINE_VERSION}

# Unpack patches
tar xzf ../${WINE_PATCH_PACK} --strip-components 1

# Apply the patches
make -C ./patches DESTDIR=${WINE_SOURCE_DIR} install

# These additional CPPFLAGS solve FS#27662 and FS#34195
export CFLAGS="$CFLAGS -DHAVE_ATTR_XATTR_H=1"
export CPPFLAGS="${CPPFLAGS/-D_FORTIFY_SOURCE=2/} -D_FORTIFY_SOURCE=0"

#export MAKEFLAGS="-j4"

# Prepare.
  ./configure \
    --prefix=${WINE_INSTALL_DIR} \
    --with-xattr \
    #--with-x \
    #--without-gstreamer \
    #--enable-win64
    # Gstreamer was disabled for FS#33655

# Build.
    #make -j
    #make install

###else
###  exit
###fi




### PIPELIGHT ### ##############################################################


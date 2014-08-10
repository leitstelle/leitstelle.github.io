#!/bin/bash
USER_HOME=${HOME}
USER_INSTALL_ROOT=${USER_HOME}/.local/build
USER_PIPELIGHT_LIB_DIR=${USER_INSTALL_ROOT}/lib/pipelight

# Prepare enviroment.
mkdir -p ${USER_INSTALL_ROOT}/src
cd ${USER_INSTALL_ROOT}/src
git clone https://bitbucket.org/mmueller2012/pipelight.git

# Configure pipelight and build it.
cd pipelight

./configure --prefix=${USER_INSTALL_ROOT} --moz-plugin-path=${USER_HOME}/.mozilla/plugins/
# --wine-path="/opt/wine-compholio/bin/wine" --gcc-runtime-dlls="/lib/x86_64-linux-gnu/"

make
make install

# Postinstall. Copy 'libpipelight.so' to available plugins. Yes, this works like that.
cp ${USER_PIPELIGHT_LIB_DIR}/libpipelight.so ${USER_PIPELIGHT_LIB_DIR}/libpipelight-flash.so
cp ${USER_PIPELIGHT_LIB_DIR}/libpipelight.so ${USER_PIPELIGHT_LIB_DIR}/libpipelight-silverlight4.so
cp ${USER_PIPELIGHT_LIB_DIR}/libpipelight.so ${USER_PIPELIGHT_LIB_DIR}/libpipelight-silverlight5.0.so
cp ${USER_PIPELIGHT_LIB_DIR}/libpipelight.so ${USER_PIPELIGHT_LIB_DIR}/libpipelight-silverlight5.1.so
cp ${USER_PIPELIGHT_LIB_DIR}/libpipelight.so ${USER_PIPELIGHT_LIB_DIR}/libpipelight-unity3d.so
cp ${USER_PIPELIGHT_LIB_DIR}/libpipelight.so ${USER_PIPELIGHT_LIB_DIR}/libpipelight-widevine.so

# Postinstall. Create link from '~/bin/pipelight-plugin' to '~/.locale/usr/bin/pipelight-plugin'.
# Need '$HOME/bin' in PATH. If this is not configured, configure it. ;-)
# mkdir -p ${USER_HOME}/bin
# cat <<EOF >> ${USER_HOME}/.bash_profile
# # if running bash
# if [ -n "$BASH_VERSION" ]; then
#     # include .bashrc if it exists
#     if [ -f "$HOME/.bashrc" ]; then
#         . "$HOME/.bashrc
#     fi
# fi
# # set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/bin" ] ; then
#     PATH="$HOME/bin:$PATH"
# fi
# EOF
# bash -l
# TODO: Write small bash profile help.
ln -s ${USER_INSTALL_ROOT}/bin/pipelight-plugin ${USER_HOME}/bin/pipelight-plugin

# Start Browser. On first run firefox detects a new plugin.
# This initalize a new wine bottle and install the plugins.
pipelight-plugin --enable silverlight

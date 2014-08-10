#!/usr/bin/env bash

RADICALE_V=0.9b1
PIP_PREFIX=~/.local

mkdir -p ${PIP_PREFIX}/src/radicale
cd ${PIP_PREFIX}/src/radicale
wget http://pypi.python.org/packages/source/R/Radicale/Radicale-${RADICALE_V}.tar.gz
# Or: git clone git://github.com/Kozea/Radicale.git git
tar xf Radicale-$RADICALE_V.tar.gz
mv Radicale-${RADICALE_V} ${RADICALE_V}

cd ${PIP_PREFIX}/src/radicale/${RADICALE_V}

# Make the installation into $PIP_PREFIX.
python3 setup.py install --install-option="--prefix=${PIP_PREFIX}"
echo 'export PATH=${PIP_PREFIX}/bin:$PATH' >> ~/.bash_profile

# Make the shell act as if it had been invoked as a login shell.
exec $SHELL -l

#!/usr/bin/env bash

# Templates to test if Software is available to react in the script

### Python ### #################################################################
# Add aliases to your bash config
cat << '__EOF__' >> ${HOME}/.bash_profile

### Python ###
alias python=python2.7
alias python2=python2.7
alias pip=pip-2.7
__EOF__

redis-server ${HOME}/.redis/conf &


### Ruby ### ###################################################################
if [ -d ${HOME}/.rbenv ]; then
	echo "The directory ~/.rbenv already exists. So we do nothing."
	pause 'Press [Enter] key to continue... or Ctl+C to abort installation.'
else
	# Git checkout.
    	git clone https://github.com/sstephenson/rbenv.git ${HOME}/.rbenv

	# Update.
	#cd ${HOME}/.rbenv
	#git pull



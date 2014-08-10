#!/usr/bin/env bash
echo -e "\e[0;45mInstallation of rbenv\e[0m"

################################################################################


# Check existing repository.
if [ -d ${HOME}/.rbenv ]; then
	echo "The directory ~/.rbenv already exists. Check it. Aborting."
	exit 2
else
	# Git checkout.
    	git clone https://github.com/sstephenson/rbenv.git ${HOME}/.rbenv
	# Update
	#cd ~/.rbenv
	#git pull
fi

# Activate rbenv.
cat << '__EOF__' >> ${HOME}/.bash_profile

### rbenv ###
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init -)"

__EOF__
# Don't forget bashrc.
cat << '__EOF__' >> ${HOME}/.bashrc

### rbenv ###
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init -)"

__EOF__

# exec $SHELL
. ${HOME}/.bash_profile

# Check rbenv.
type rbenv

# Install ruby-build - The `rbenv install` command.
git clone https://github.com/sstephenson/ruby-build.git ${HOME}/.rbenv/plugins/ruby-build
# Install rbenv-gem-rehash - The auto `rbenv rehash` when installing new gems.
git clone https://github.com/sstephenson/rbenv-gem-rehash.git ${HOME}/.rbenv/plugins/rbenv-gem-rehash

# List available installations.
#rbenv install --list

# Install ruby (need some time).
rbenv install 2.1.2
rbenv install 1.9.3-p547
# Rehash rbenv. This write changes into ~/.rbenv/shims. Important if gems provide some new bins.
rbenv rehash

# Set global ruby version.
rbenv global 2.1.2

# Hooks rbenv into the shell. (Already happend after `. ~/.bash_profile`. use `rbenv init -` to see more informations.)
#rbenv init

# Print rbenv used ruby version.
echo "rbenv version:"
rbenv version

# Install options for gem.
# Old: echo "gem: --user-install --no-rdoc --no-ri" > ~/.gemrc
# Do not use the `--user-install` option! This will install gems into `~/.gem` dir and not into the rbenv version specific folder!
echo "gem: --no-rdoc --no-ri" > ${HOME}/.gemrc


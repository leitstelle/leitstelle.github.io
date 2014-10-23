#!/usr/bin/env bash
################################################################################
# No warranty! For nothing. Use it at your own risk.
# Author: Frank Zisko, 2014
# Version: 1.1.0.5
#
#
# OpenProject 3.0.14 installation at  an uberspace account.
# Using:
# Ruby 2.1.2 via rbenv 0.4.0
# Ruby 2.1.1 via uberspace
#
################################################################################


# Install root dir.
WORKSPACE=${HOME}/workspace

# Projectname (used for subdomain name in your domain and uberspace domain).
PROJECT=openproject

# Domain. 
# Uberspace user domain (<uberuser>.<uberserver>.uberspace.de) will be automatically added.
DOMAINNAME="${PROJECT}.example.com"

# Port.
PORT=61000

# Check if port is (already) unused.
if [[ -z $(netstat -tulpen | grep ${PORT}) ]]; then
    echo "Your choosen \$PORT is available."
else
    echo "Your choosen \$PORT is not available. Choose another."
    echo "Aborting the script!"
    echo " "
    exit 2
fi


### Ruby ### ###################################################################
# You need Ruby in your $PATH (e.g. via .bashrc file)!
# If you are not using rbenv, like me, it's will also work. You get some 'unknown command' outputs for every 'rbenv …' line. It's not nice, but it works for both: Uberspace Ruby and rbenv Ruby.
rbenv install -s 2.1.2
rbenv rehash


### Download ### ############################################################
mkdir -p ${WORKSPACE}; cd ${WORKSPACE}

if [ -d openproject-git ]; then
	echo "Source directory openproject exists. Updateing and copying data from there."
	cd ${WORKSPACE}/openproject-git
	git pull
	#git checkout stable
	git checkout v3.0.14
else
    	git clone https://github.com/opf/openproject.git ${WORKSPACE}/openproject-git
	cd ${WORKSPACE}/openproject-git
	#git checkout stable
	git checkout v3.0.14
fi


### Prepare ### ################################################################
cd ${WORKSPACE}
rm -Rf openproject && mkdir -p openproject
cp -R openproject-git/* openproject/


### Config ### #################################################################
cd ${WORKSPACE}/openproject
rbenv local 2.1.2

#### configuration.yml ####
cat > config/configuration.yml <<__EOF__
# default configuration options for all environments
default:
  # disable browser cache for security reasons
  # see: https://websecuritytool.codeplex.com/wikipage?title=Checks#http-cache-control-header-no-store
  disable_browser_cache: true
  # defines where session data is stored
  # possible values are :cookie_store, :cache_store, :active_record_store
  session_store: :cookie_store

# specific configuration options for production environment
production:
  session_store: :cache_store
  email_delivery:
    delivery_method: :sendmail
    sendmail_settings:
      location: /usr/sbin/sendmail
      arguments: -i

# specific configuration options for development environment
# that overrides the default ones
development:
  email_delivery_method: :letter_opener

# Configuration for the test environment
test:
  email_delivery_method: :test
__EOF__

#### database.yml ####
cat > config/database.yml <<__EOF__
production:
  adapter: mysql2
  database: ${USER}_openproject
  host: localhost
  username: ${USER}
  password: `my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'`
  encoding: utf8

#development:
#  adapter: mysql2
#  database: ${USER}_openproject_dev
#  host: localhost
#  username: ${USER}
#  password: `my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'`
#  encoding: utf8

#test:
#  adapter: mysql2
#  database: ${USER}_openproject_test
#  host: localhost
#  username: ${USER}
#  password: `my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'`
#  encoding: utf8
__EOF__


### Gems ### ###################################################################
cd ${WORKSPACE}/openproject
cat > Gemfile.local <<__EOF__
#gem 'unicorn'
gem 'rails_12factor'
__EOF__

gem install bundler
rbenv rehash

# For ruby from system:
#bundle install --path ~/.gem --without postgres:sqlite:test
# For ruby from local user rbenv:
bundle install --path vendor/bundle --without postgres:sqlite:test:development
	# "--path vendor/bundle" will install gems in the project folder.


### Setup ### ##################################################################
cd ${WORKSPACE}/openproject
bundle exec rake generate_secret_token

#### DB ####
mysql -e "DROP DATABASE ${USER}_openproject;"
#mysql -e "DROP DATABASE ${USER}_openproject_dev;"
#mysql -e "DROP DATABASE ${USER}_openproject_test;"

mysql -e "CREATE DATABASE ${USER}_openproject CHARACTER SET utf8"
#mysql -e "CREATE DATABASE ${USER}_openproject_dev CHARACTER SET utf8"
#mysql -e "CREATE DATABASE ${USER}_openproject_test CHARACTER SET utf8"

RAILS_ENV=production bundle exec rake db:create --all
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake db:seed
RAILS_ENV=production bundle exec rake assets:precompile


### Startscripts ### ###########################################################

#### Uberspace service ####
test -d ~/service || uberspace-setup-svscan

#### Web ####
mkdir -p ~/bin

cat <<__EOF__ > ~/bin/openproject-web
#!/usr/bin/env bash
export HOME=${HOME}
export USER=${USER}
source \${HOME}/.bash_profile
cd ${WORKSPACE}/openproject
export RAILS_ENV=production
exec bundle exec unicorn --port ${PORT} --env production
__EOF__
#RAILS_ENV=production bundle exec unicorn --port ${PORT} --env production
chmod +x ~/bin/openproject-web
uberspace-setup-service openproject-web ~/bin/openproject-web

#### Worker ####
cat <<__EOF__ > ~/bin/openproject-worker
#!/bin/sh
export HOME=${HOME}
export USER=${USER}
source \${HOME}/.bash_profile
cd ${WORKSPACE}/openproject
export RAILS_ENV=production
exec bundle exec rake jobs:work
__EOF__
#RAILS_ENV=production bundle exec rake jobs:work
chmod +x ~/bin/openproject-worker
uberspace-setup-service openproject-worker ~/bin/openproject-worker


### Rewrite Proxy ### ##########################################################
mkdir -p /var/www/virtual/${USER}/${PROJECT}.${USER}.$(hostname -a).uberspace.de
ln -s /var/www/virtual/${USER}/${PROJECT}.${USER}.$(hostname -a).uberspace.de /var/www/virtual/${USER}/${DOMAINNAME}

cd /var/www/virtual/${USER}/${PROJECT}.${USER}.$(hostname -a).uberspace.de

cat <<__EOF__ > .htaccess
RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteCond %{ENV:HTTPS} !=on
RewriteRule .* https://%{SERVER_NAME}%{REQUEST_URI} [R=301,L]

RewriteRule (.*) http://localhost:${PORT}/\$1 [P]
__EOF__


### Start/Stop ### #############################################################
echo "Restart OpenProject services:"
echo "svc -du ~/service/openproject-web"
echo "svc -du ~/service/openproject-worker"


### Logs ### ###################################################################
echo "Logs will be written in:"
echo "~/service/openproject-web/log/main/current"
echo "~/service/openproject-worker/log/main/current"


### Uninstall ### ##############################################################

#### Services ####
#  cd ~/service/openproject-web
#  rm ~/service/openproject-web
#  svc -dx . log
#  rm -rf ~/etc/run-openproject-web

#  cd ~/service/openproject-worker
#  rm ~/service/openproject-worker
#  svc -dx . log
#  rm -rf ~/etc/run-openproject-worker

#### Installation files and folder ####
#rm ~/bin/openproject-web
#rm ~/bin/openproject-worker
#rm -rf /var/www/virtual/${USER}/${PROJECT}.${USER}.$(hostname -a).uberspace.de
#rm /var/www/virtual/${USER}/${DOMAINNAME}
#rm -rf ~/workspace/openproject
###rm -rf ~/workspace/openproject-git


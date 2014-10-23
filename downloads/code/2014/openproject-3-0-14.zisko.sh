#!/usr/bin/env bash
################################################################################
# No warranty! For nothing. Use it at your own risk.
# Author: Frank Zisko, 2014
# Version: 1.0
#
#
# OpenProjecr 3.0.14 installation at uberspace account using rbenv.
# Using:
# Ruby 2.1.2 via rbenv 0.4.0
# Ruby 2.1.1 via uberspace
#
################################################################################


# Pause if need some break in your script.
# Use it: pause 'Press [Enter] key to continue...'
function pause(){
   read -p "$*"
}

# Projectname (used for subdomain name).
PROJECT=project

# Domain.
DOMAINNAME="${PROJECT}.zisko.industries"

# Port.
PORTNUM=62825
echo "Check wanted port number: (If next line is empty, everything is all right.)"
netstat -tulpen | grep ${PORTNUM}
echo ""

# Install root dir.
WORKSPACE=${HOME}/workspace


### Ruby ### ###################################################################
rbenv install -s 2.1.2
rbenv rehash


### Download ### ############################################################
mkdir -p ${WORKSPACE}; cd ${WORKSPACE}

if [ -d openproject-git ]; then
	echo "Source directory openproject exists. Updateing and copying data from there."
	cd ${WORKSPACE}/openproject-git
	git pull
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

#cd ${WORKSPACE}/openproject
#cat > .bundle/config <<__EOF__
#---
#BUNDLE_FROZEN: '1'
#BUNDLE_PATH: vendor/bundle
#BUNDLE_WITHOUT: development:test:postgres:sqlite
#BUNDLE_DISABLE_SHARED_GEMS: '1'
#__EOF__


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
	# "--path vendor/bundle" installs it in project folder.


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
exec bundle exec unicorn --port ${PORTNUM} --env production
__EOF__
#RAILS_ENV=production bundle exec unicorn --port ${PORTNUM} --env production
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

RewriteRule (.*) http://localhost:${PORTNUM}/\$1 [P]
__EOF__


### Start/Stop ### #############################################################
echo "Restart both OpenProject services:"
echo "svc -du ~/service/openproject-web"
echo "svc -du ~/service/openproject-worker"


### Logs ### ###################################################################
echo "Logs:"
echo "~/service/openproject-web/log/main/current"
echo "~/service/openproject-worker/log/main/current"



#cat > .htaccess <<'__EOF__'
#RewriteEngine On
#RewriteBase /
# 
## http:// -> https://
#RewriteCond %{SERVER_PORT} 80
#RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R,L]

#RewriteRule ^$ index.html [QSA]
#RewriteRule ^([^.]+)$ $1.html [QSA]
#RewriteCond %{REQUEST_FILENAME} !-f
#RewriteRule ^(.*)$ wrapper.fcgi [QSA,L]
# 
#__EOF__
	

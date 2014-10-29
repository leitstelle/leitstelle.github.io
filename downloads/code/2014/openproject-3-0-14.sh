#!/usr/bin/env bash
################################################################################
# Author: Frank Zisko, 2014
# Version: 2.0.0.15
# Licence: MIT
# No warranty! For nothing. Use it at your own risk.
#
# About: OpenProject 3.0.14 installation at an uberspace account.
# Using 
# Ruby 2.1.2 via rbenv
# or 
# Ruby 2.1.2 via uberspace 
# (Automatically choosen.)
################################################################################


### Logging ### ################################################################
# Call this script again with logging parameters.
if [ -z "$IS_CALLED" ]; then
    #echo "Recall script with logging."    
    export IS_CALLED=1
    
    SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/`basename "${BASH_SOURCE[0]}"`
    LOG_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/`basename "${BASH_SOURCE[0]}"`.log
    . ${SCRIPT_PATH} ${1} 2>&1 | tee "${LOG_PATH}"

    #echo "End recursive script call."
    # Exit here! If not, you'll go into endless recursive loop!
    exit
    echo "Never reach this."
fi


### Log ### ####################################################################
JOB_NAME="Install OpenProject"
echo "### Start Job: ${JOB_NAME} at $(date "+%Y-%m-%dT%H:%M:%S"). ###"
time_begin=$(date +"%s")


### Variables ### ##############################################################
# You just have to adjust these four variables.

# Install root directory.
WORKSPACE=${HOME}/workspace

# Projectname (used for subdomain name in your domain and uberspace domain).
PROJECT=project

# Domain. 
# Uberspace user domain (<uberuser>.<uberserver>.uberspace.de) will be automatically added.
# It does not matter, if you don't have an own domain.
DOMAINNAME="${PROJECT}.example.com"

# Port.
PORT=61000


### Uninstall ### ##############################################################
if [ "${1}" == "uninstall" ]; then
    echo "Uninstallation..."

    #### Services ####
    cd ~/service/openproject-web
    rm ~/service/openproject-web
    svc -dx . log
    rm -rf ~/etc/run-openproject-web

    cd ~/service/openproject-worker
    rm ~/service/openproject-worker
    svc -dx . log
    rm -rf ~/etc/run-openproject-worker
  
    #### Installation files and folder ####
    rm ~/bin/openproject-web
    rm ~/bin/openproject-worker
    rm -rf /var/www/virtual/${USER}/${PROJECT}.${USER}.$(hostname -a).uberspace.de
    # Prevent deleting ${USER}s www directory, if ${DOMAINNAME} is empty.
    if [ -n "${DOMAINNAME}" ]; then
        rm /var/www/virtual/${USER}/${DOMAINNAME}
    fi
    rm -rf ~/workspace/openproject
    #rm -rf ~/workspace/openproject-git
  
    #### DB ####
    # Drop existing DBs.
        # Check if database is existing.
        # Connect to DB and instantly exiting DB returns nothing.
        # No exisitng DB returns an error.
    if [ -z "$(mysql --user="${USER}" --password=`my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'` --database="${USER}_openproject" --execute=exit 2>&1 >/dev/null)" ]; then
        echo "Drop existing DB ${USER}_openproject."
        mysql -e "DROP DATABASE ${USER}_openproject;"
    fi

    if [ -z "$(mysql --user="${USER}" --password=`my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'` --database="${USER}_openprojects_dev" --execute=exit 2>&1 >/dev/null)" ]; then
        echo "Drop existing DB ${USER}_openproject_dev."
        mysql -e "DROP DATABASE ${USER}_openproject_dev;"
    fi

    if [ -z "$(mysql --user="${USER}" --password=`my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'` --database="${USER}_openprojects_test" --execute=exit 2>&1 >/dev/null)" ]; then
        echo "Drop existing DB ${USER}_openproject_test."
        mysql -e "DROP DATABASE ${USER}_openproject_test;"
    fi

    echo "Uninstallation finished."
    exit 0
fi


### Check ### ##################################################################
# Check existing installation of openproject-web.
if [ -f ~/bin/openproject-web ]; then
    echo "~/bin/openproject-web exists."
    IS_INSTALLED=1
fi
# Check existing installation of openproject-worker.
if [ -f ~/bin/openproject-worker ]; then
    echo "~/bin/openproject-worker exists."
    IS_INSTALLED=1
fi
# Check termination condition.
if [ -n "${IS_INSTALLED}" ]; then
    echo "OpenProject files found. Maybe it is already installed. Aborting."
    exit 1
fi


### Ruby ### ###################################################################
# You need Ruby in your $PATH (e.g. via .bashrc file)!

# Check if port is (already) unused.
if [ -z "$(netstat -tulpen | grep ${PORT})" ]; then
    echo "Your choosen \$PORT:${PORT} is available."
else
    echo "Your choosen \$PORT:${PORT} is not available. Choose another."
    echo "Aborting the script."
    exit 2
fi

# Check if rbenv ruby is used. Important for 'gem install …' commnd.
if [ -z "$(command -v rbenv)" ]; then
    echo "'rbenv' command not found."
    IS_RBENV=0
else
    echo "'rbenv' command found."
    IS_RBENV=1
    echo "rbenv version:"
    rbenv --version
fi

# Check if ruby is available.
if [ -z "$(command -v ruby)" ]; then
    echo "'ruby' command not found."
    RUBY_FOUND=false
else
    RUBY_FOUND=true
    echo "'ruby' command found."
fi
# Check if gem is available.
if [ -z "$(command -v gem)" ]; then
    echo "'gem' command not found."
    GEM_FOUND=false
else
    GEM_FOUND=true
    echo "'gem' command found."
fi
# Check termination condition.
if [[ ( ${RUBY_FOUND} == true ) && ( ${GEM_FOUND} == true ) ]]; then
    echo " "
else
    echo "Ruby is not complete. Aborting."
    exit 3
fi

# Install rbenv ruby version.
if [ "$IS_RBENV" == 1 ]; then
    echo "'rbenv install -s 2.1.2'."
    rbenv install -s 2.1.2
    rbenv rehash 
else
    echo "PATH:"
    echo $PATH
fi


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
# With this all dot-leading files and folders will not be copied.
rm -Rf openproject && mkdir -p openproject
cp -R openproject-git/* openproject/


### Config ### #################################################################
cd ${WORKSPACE}/openproject

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

if [ "$IS_RBENV" == "1" ]; then
    echo "'rbenv local 2.1.2'."
    rbenv local 2.1.2
fi

# Uberspace ruby installs into ~/.gem. rbenv ruby into project folder.
if [ "$IS_RBENV" == "1" ]; then
    gem install bundler
    rbenv rehash
else
    gem install --user bundler
fi

cat > Gemfile.local <<__EOF__
gem 'rails_12factor'
__EOF__

# This works for Uberspace ruby and rbenv ruby.
# '--path vendor/bundle' will install gems in the project folder. 
# Normally on Uberspace you choose '--path ~/.gem'.
bundle install --path vendor/bundle --without postgres:sqlite:development:test


### Setup ### ##################################################################
cd ${WORKSPACE}/openproject

bundle exec rake generate_secret_token

#### DB ####

# Drop existing DBs.
    # Check if database is existing.
    # Connect to DB and instantly exiting DB returns nothing.
    # No exisitng DB returns an error.
if [ -z "$(mysql --user="${USER}" --password=`my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'` --database="${USER}_openproject" --execute=exit 2>&1 >/dev/null)" ]; then
    echo "Drop existing DB ${USER}_openproject."
    mysql -e "DROP DATABASE ${USER}_openproject;"
fi

if [ -z "$(mysql --user="${USER}" --password=`my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'` --database="${USER}_openprojects_dev" --execute=exit 2>&1 >/dev/null)" ]; then
    echo "Drop existing DB ${USER}_openproject_dev."
    mysql -e "DROP DATABASE ${USER}_openproject_dev;"
fi

if [ -z "$(mysql --user="${USER}" --password=`my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'` --database="${USER}_openprojects_test" --execute=exit 2>&1 >/dev/null)" ]; then
    echo "Drop existing DB ${USER}_openproject_test."
    mysql -e "DROP DATABASE ${USER}_openproject_test;"
fi

# Create new DB.
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
if [ -n "${DOMAINNAME}" ]; then
    ln -s /var/www/virtual/${USER}/${PROJECT}.${USER}.$(hostname -a).uberspace.de /var/www/virtual/${USER}/${DOMAINNAME}
fi

cd /var/www/virtual/${USER}/${PROJECT}.${USER}.$(hostname -a).uberspace.de

cat <<__EOF__ > .htaccess
RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteCond %{ENV:HTTPS} !=on
RewriteRule .* https://%{SERVER_NAME}%{REQUEST_URI} [R=301,L]

RewriteRule (.*) http://localhost:${PORT}/\$1 [P]
__EOF__


### Info ### ###################################################################
echo " "
echo " "
echo "Restart OpenProject services:"
echo "    svc -du ~/service/openproject-web"
echo "    svc -du ~/service/openproject-worker"


### Info ### ###################################################################
echo " "
echo " "
echo "Logs will be written in:"
echo "    ~/service/openproject-web/log/main/current"
echo "    ~/service/openproject-worker/log/main/current"


### Info ### ###################################################################
echo " "
echo " "
echo "For uninstallation call:"
echo "    $(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/`basename "${BASH_SOURCE[0]}"` uninstall"


### Log ### ####################################################################
echo " "
echo " "
time_end=$(date +"%s")
time_diff=$((${time_end}-${time_begin}))
echo "### Finished Job: ${JOB_NAME} at $(date "+%Y-%m-%dT%H:%M:%S"). ###"
echo "    $((${time_diff} / 60)) minutes and $((${time_diff} % 60)) seconds elapsed."


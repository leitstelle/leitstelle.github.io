#!/usr/bin/env bash
echo -e "\e[0;45mInstallation of Redmine 2.5.\e[0m"
cd

################################################################################

# Subfolder or subdomain?
SUBFOLDER=false
DOMAINNAME="redmine.example.com"


# rbenv.
if [ -f ${HOME}/.rbenv ]; then
	echo "~/.rbenv exists. So I assume rbenv is correctly installed. Here is nothing to do."
else
    	echo "~/.rbenv does not exist. So I install and configure it. This will need some time."
	cd ${HOME}
	wget -O ${HOME}/rbenv-install.sh https://leitstelle.github.io/downloads/code/2014/rbenv-install.sh
	chmod u+x rbenv-install.sh
	./rbenv-install.sh
	. ${HOME}/.bash_profile
fi

# Ruby.
rbenv install -s 2.1.2
rbenv rehash

# Apache readable directory, but not html doc folder
/var/www/virtual/${USER}

# Check existing repository.
if [ -d redmine-git ]; then
	echo "Source directory redmine-git exists. Updateing and copying data from there."
	cd redmine-git
	git pull
else
	.
    	git clone https://github.com/redmine/redmine.git -b 2.5-stable redmine-git
fi

## Checkout stable version.
#cd /var/www/virtual/$USER/redmine-git
#git checkout 2.5-stable
#cd ..

# Clear existing redmine installation.
rm -Rf redmine && mkdir -p redmine
cp -R redmine-git/* redmine/

# REDMINE DIR.
cd redmine
rbenv local 2.1.2

# Install bundler for local rbenv version, if not already done.
gem install bundler
rbenv rehash

# Add fcgi to gem installation.
echo "gem 'fcgi'" > Gemfile.local

# Create MySQL database.
# Be carefully to drop : 
mysql -e "DROP DATABASE ${USER}_redmine;"
mysql -e "CREATE DATABASE ${USER}_redmine CHARACTER SET utf8"

cat > config/database.yml <<__EOF__
production:
  adapter: mysql2
  database: ${USER}_redmine
  host: localhost
  username: $USER
  password: `my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'`
  encoding: utf8
__EOF__

# Install dependencies.
# Old: bundle install --path ~/.gem --without development test postgresql sqlite
# Do not use `--path ~/.gem` this is not compatible with rbenv!
bundle install --without development test postgresql sqlite
rbenv rehash

# Generate key.
rake generate_secret_token

# Migrate database. Creates also admin account.
rake db:migrate RAILS_ENV=production

# Load default configuration.
rake redmine:load_default_data RAILS_ENV=production
# 	Select your prefered langugae.

# Configure to send emails.
cat > config/configuration.yml <<__EOF__
production:
  email_delivery:
    delivery_method: :sendmail
__EOF__

# FastCGI.
cd public
cp -a dispatch.fcgi.example dispatch.fcgi
# FastCGI wrapper.
cat > wrapper.fcgi <<__EOF__
#!/bin/bash
export USER=$USER
export HOME=$HOME
source \$HOME/.bash_profile
export RAILS_ENV=production
exec ./dispatch.fcgi
__EOF__
chmod 755 wrapper.fcgi

# Make public directory readable.
chmod 755 .


### SUBFOLDER OR SUBDOMAIN? ###
if [ "${SUBFOLDER}" = true ]; then
	# SUBFOLDER
	echo "Configure for usage of redmine in a subfolder."
	cd /var/www/virtual/$USER/redmine
	echo 'Redmine::Utils::relative_url_root = "/redmine"' >> config/environment.rb
	# Bugfix
	sed -i -e "s/^# Initialize the rails application/RedmineApp::Application.routes.default_scope = { :path => '\/redmine', :shallow_path => '\/redmine' }\n\n# Initialize the rails application/" config/environment.rb

	# Create link.
	cd /var/www/virtual/$USER/html
	ln -s ../redmine/public redmine
	
	# '.htaccess'
	cat > .htaccess <<'__EOF__'
	<IfModule mod_fastcgi.c>
	        AddHandler fastcgi-script .fcgi
	</IfModule>
	<IfModule mod_fcgid.c>
	        AddHandler fcgid-script .fcgi
	</IfModule>
	Options + SymLinksIfOwnerMatch +ExecCGI
	 
	RewriteEngine On
	 
	RewriteRule ^$ index.html [QSA]
	RewriteRule ^([^.]+)$ $1.html [QSA]
	RewriteCond %{REQUEST_FILENAME} !-f
	RewriteRule ^(.*)$ wrapper.fcgi [QSA,L]
	 
	ErrorDocument 500 "<h2>Application error</h2>Rails application failed to start properly"
	__EOF__
else
	# SUBDOMAIN
	echo "Configure for usage of redmine in a subdomain."
	# '.htaccess'.
	cd /var/www/virtual/$USER/redmine/public
	cat > .htaccess <<'__EOF__'
	<IfModule mod_fastcgi.c>
	        AddHandler fastcgi-script .fcgi
	</IfModule>
	<IfModule mod_fcgid.c>
	        AddHandler fcgid-script .fcgi
	</IfModule>
	Options +SymLinksIfOwnerMatch +ExecCGI
	 
	RewriteEngine On
	RewriteBase /
	 
	# http:// -> https://
	RewriteCond %{SERVER_PORT} 80
	RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R,L]
	
	RewriteRule ^$ index.html [QSA]
	RewriteRule ^([^.]+)$ $1.html [QSA]
	RewriteCond %{REQUEST_FILENAME} !-f
	RewriteRule ^(.*)$ wrapper.fcgi [QSA,L]
	 
	ErrorDocument 500 "<h2>Application error</h2>Rails application failed to start properly"
	__EOF__
	
	# Create link.
	cd /var/www/virtual/$USER
	ln -s redmine/public redmine.$USER.$(hostname -a).uberspace.de
	ln -s redmine/public ${DOMAINNAME}
fi

# Call Webpage information.
echo -e "\e[0mInstallation of Redmine 2.5 done.\e[0m"
echo -e "\e[0;45mCall the your Redmine web page and log into admin account, to change the beginning password. User:\e[0;93madmin\e[0;45m Password:\e[0;93madmin\e[0m"


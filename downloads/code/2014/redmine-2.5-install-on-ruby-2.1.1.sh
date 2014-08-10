#!/usr/bin/env bash
echo -e "\e[0;45mInstallation of Redmine 2.5.\e[0m"

################################################################################

# Subfolder or subdomain?
SUBFOLDER=false
DOMAINNAME="redmine.example.com"


# Activate Ruby
cat <<'__EOF__' >> ~/.bash_profile
export PATH=/package/host/localhost/ruby-2.1.1/bin:$PATH
export PATH=$HOME/.gem/ruby/2.1.0/bin:$PATH
__EOF__
. ~/.bash_profile

## Activate Ruby using 'rbenv'.
#cat <<'__EOF__' >> ~/.bash_profile
#export PATH=$HOME/.rbenv/shims:$PATH
#__EOF__
#. ~/.bash_profile

# Prepare gem.
echo "gem: --user-install --no-rdoc --no-ri" > ~/.gemrc

# We need bundler to install all gem dependencies for redmine.
#Old: gem install --user-install --no-rdoc --no-ri bundler
gem install bundler


# Apache readable directory, but not html doc folder.
cd /var/www/virtual/$USER

# Check existing repository.
if [ -d redmine-2.5 ]; then
	echo "Source directory redmine-2.5 exists. Copying data from there."
else
    	svn co http://svn.redmine.org/redmine/branches/2.5-stable redmine-2.5
fi

# Clear existing redmine installation.
rm -Rf redmine && mkdir -p redmine
cp -R redmine-2.5/* redmine/

# REDMINE DIR
cd redmine

# Add fcgi to gem installation.
echo "gem 'fcgi'" > Gemfile.local

# Create MySQL database.
# Be carefully to drop : 
mysql -e "DROP DATABASE \`${USER}_redmine\`;"
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
bundle install --path ~/.gem --without development test postgresql sqlite

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

#!/usr/bin/env bash

DOMAINNAME="redmine.example.com"

cd /var/www/virtual/$USER
svn co http://svn.redmine.org/redmine/branches/2.5-stable redmine
cd redmine

# fastcgi.
echo "gem 'fcgi'" > Gemfile.local

# Create database.
mysql -e "CREATE DATABASE ${USER}_redmine CHARACTER SET utf8"

# Configure 'Redmine' database.
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

# Initialize database.
rake generate_secret_token

# Redmine create db structure and admin account.
rake db:migrate RAILS_ENV=production

# Get default config.
rake redmine:load_default_data RAILS_ENV=production

# Config to send email.
cat > config/configuration.yml <<__EOF__
production:
  email_delivery:
    delivery_method: :sendmail
__EOF__

# Configure URL.
echo 'Redmine::Utils::relative_url_root = "/"' >> config/environment.rb

# Bugfix http://www.redmine.org/issues/11881
sed -i -e "s/^# Initialize the rails application/RedmineApp::Application.routes.default_scope = { :path => '\/redmine', :shallow_path => '\/redmine' }\n\n# Initialize the rails application/" config/environment.rb

# Connect to fastCGI.
cd public
cp -a dispatch.fcgi.example dispatch.fcgi

# Wrapper for Ruby and Rails config.
cat > wrapper.fcgi <<__EOF__
#!/bin/bash
export USER=$USER
export HOME=$HOME
source \$HOME/.bash_profile
export RAILS_ENV=production
exec ./dispatch.fcgi
__EOF__
chmod 755 wrapper.fcgi

# Rights of this directory that suEXEC will run it.
chmod 755 .

# Configure subdomain.
cd /var/www/virtual/$USER
#ln -s redmine/public redmine.$USER.$(hostname -a).uberspace.de
ln -s redmine/public ${DOMAINNAME}

# htaccess.
cd ${DOMAINNAME}
cat > .htaccess <<'__EOF__'
<IfModule mod_fastcgi.c>
        AddHandler fastcgi-script .fcgi
</IfModule>
<IfModule mod_fcgid.c>
        AddHandler fcgid-script .fcgi
</IfModule>
# Old: Options +FollowSymLinks +ExecCGI
# New for uberspace:
Options +SymLinksIfOwnerMatch +ExecCGI
 
RewriteEngine On
RewriteBase /
 
# http:// -> https://
RewriteCond %{SERVER_PORT} 80
RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R,L]

# fcgi wrapper
RewriteRule ^$ index.html [QSA]
RewriteRule ^([^.]+)$ $1.html [QSA]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ wrapper.fcgi [QSA,L]
 
ErrorDocument 500 "<h2>Application error</h2>Rails application failed to start properly"
__EOF__
  
echo -e "\e[93m  IT'S FINISHED!  \e[0m"

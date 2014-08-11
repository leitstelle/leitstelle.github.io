#!/usr/bin/env bash

# Init. Use it: pause 'Press [Enter] key to continue...'
function pause(){
   read -p "$*"
}

#DOMAINNAME="gitlab.${USER}.$(hostname -a).uberspace.de"
DOMAINNAME="gitlab.example.com"
INTERNPORT="54321"
# Check availablebility of port.
netstat -tulpen | grep ${INTERNPORT}
#	No answer, if port is unused.

WORKSPACE=${HOME}/workspace
mkdir -p ${WORKSPACE}
cd ${WORKSPACE}


################################################################################

# GitLab 7.1-stable installation on uberspace account wioth rbenv.

# Using:
# Git 2.0.4
# Redis 2.8.13
# Python 2.7.3
# Ruby 2.1.2 via rbenv 0.4.0
# Ruby 2.1.1 via uberspace


### Python ### #################################################################
# Add aliases to your bash config
cat << '__EOF__' >> ${HOME}/.bash_profile

### Python ###
alias python=python2.7
alias python2=python2.7
alias pip=pip-2.7
__EOF__

# Don't forget bashrc. Because services don't use a login shell.
cat << '__EOF__' >> ${HOME}/.bashrc

### Python ###
alias python=python2.7
alias python2=python2.7
alias pip=pip-2.7
__EOF__


### Toasts ### #################################################################
# Git.
toast arm https://www.kernel.org/pub/software/scm/git/git-2.0.4.tar.gz
git config --global user.name "Git"
git config --global user.email "${USER}@localhost"
git config --global core.autocrlf input

# Redis.
toast arm http://download.redis.io/releases/redis-2.8.13.tar.gz
mkdir -p ${HOME}/.redis
cat > ${HOME}/.redis/conf <<__EOF__
unixsocket ${HOME}/.redis/sock
daemonize no
# For logging in uberspace service.
# logfile stdout
# For logging in a file.
logfile ${HOME}/.redis/log
port 0
__EOF__
redis-server ${HOME}/.redis/conf &
# Access: redis-cli -s ${HOME}/.redis/conf &


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
	
	# Activate profile changes.
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

	# Set global ruby version.
	rbenv global 2.1.2
	# Rehash rbenv. This write changes into ~/.rbenv/shims. 
	# Important if gems provide some new bins.
	# Or the environment changes.
	rbenv rehash

	# Hooks rbenv into the shell. 
	# Already happend after `. ~/.bash_profile`.
	# Use `rbenv init -` to see more informations.
	#rbenv init
	
	# Print rbenv used ruby version.
	echo "rbenv version:"
	rbenv version
	
	# Install options for gem.
	# Old: echo "gem: --user-install --no-rdoc --no-ri" > ~/.gemrc
	# Do not use the `--user-install` option! This will install gems into `~/.gem` dir and not into the rbenv 	version specific folder!
	echo "gem: --no-rdoc --no-ri" > ${HOME}/.gemrc

	# Install bundler for both installed versions.
	# For 1.9.3
	rbenv shell 1.9.3-p547
	gem install bundler
	# For 2.1.2
	rbenv shell 2.1.2
	gem install bundler
	# Leave rbenv shell
	rbenv shell --unset
fi

### Gitlab Shell ### ###########################################################
git clone https://gitlab.com/gitlab-org/gitlab-shell.git ${WORKSPACE}/gitlab-shell
cd ${WORKSPACE}/gitlab-shell
rbenv local 2.1.2
git fetch origin && git reset --hard $(git describe v1.9.6 || git describe origin/v1.9.6)

cat > ${WORKSPACE}/gitlab-shell/config.yml <<__EOF__
---
user: ${USER}
#gitlab_url: http://gitlab.${USER}.$(hostname -a).uberspace.de/
gitlab_url: http://${DOMAINNAME}/

http_settings:
#  user: someone
#  password: somepass
#  ca_file: /etc/ssl/cert.pem
#  ca_path: /etc/pki/tls/certs
  self_signed_cert: false

repos_path: "${WORKSPACE}/repositories/"
auth_file: "${HOME}/.ssh/authorized_keys"

redis:
  bin: ${HOME}/.toast/armed/bin/redis-cli
  # host: 127.0.0.1
  # port: 6379
  socket: ${HOME}/.redis/sock
  # socket: /tmp/redis.socket # Only define this if you want to use sockets
  namespace: resque:gitlab

# Log file.
log_file: "${WORKSPACE}/gitlab-shell/gitlab-shell.log"
log_level: INFO

# Audit usernames.
audit_usernames: false
__EOF__

# Change ${WORKSPACE}/gitlab-shell/hooks/update
#        #!/usr/bin/env ruby  ->  #!${HOME}/.rbenv/shims/ruby
# Old: sed -i -e "s=\/usr\/bin\/env ruby=${HOME}\/.rbenv\/shims\/ruby=g" ${WORKSPACE}/gitlab-shell/hooks/update
sed -i -e "s=\/usr\/bin\/env ruby=$(which ruby)=g" ${WORKSPACE}/gitlab-shell/hooks/update

./bin/install


### GitLab ### #################################################################
git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b 7-1-stable ${WORKSPACE}/gitlab
cd ${WORKSPACE}/gitlab
rbenv local 2.1.2

# Some folders
mkdir -p log
mkdir -p tmp/pids
mkdir -p tmp/sockets
mkdir -p public/uploads
# Allow access to folders.
chown -R ${USER} log/
chown -R ${USER} tmp/
chmod -R u+rwX ${WORKSPACE}/repositories
chmod -R u+rwX log/
chmod -R u+rwX tmp/
chmod -R u+rwX tmp/pids/
chmod -R u+rwX tmp/sockets/
chmod -R u+rwX public/uploads
# GitLab Satelittes.
mkdir -p ${WORKSPACE}/gitlab-satellites
chmod u+rwx,g=rx,o-rwx ${WORKSPACE}/gitlab-satellites

# Configure the application main config file.
cat > config/gitlab.yml <<__EOF__
# # # # # # # # # # # # # # # # # #
# GitLab application config file  #
# # # # # # # # # # # # # # # # # #

production: &base
  #
  # 1. GitLab app settings
  # ==========================

  ## GitLab settings
  gitlab:
    ## Web server settings (note: host is the FQDN, do not include http://)
    host: ${DOMAINNAME}
    port: 80
    https: true

    user: ${USER}
    email_from: ${USER}@${DOMAINNAME}

    ## User settings
    default_projects_limit: 10
    # default_can_create_group: false  # default: true
    # username_changing_enabled: false # default: true - User can change her username/namespace
    ## Default theme
    ##   BASIC  = 1, MARS   = 2, MODERN = 3, GRAY   = 4, COLOR  = 5
    default_theme: 2 # default: 2

    ## Users management
    # default: false - Account passwords are not sent via the email if signup is enabled.
    # signup_enabled: true
    #
    # default: true - If set to false, standard login form won't be shown on the sign-in page
    # signin_enabled: false

    # Restrict setting visibility levels for non-admin users.
    # The default is to allow all levels.
    #restricted_visibility_levels: [ "public" ]

    ## Automatic issue closing
    # If a commit message matches this regular expression, all issues referenced from the matched text will be closed.
    # This happens when the commit is pushed or merged into the default branch of a project.
    # When not specified the default issue_closing_pattern as specified below will be used.
    # issue_closing_pattern: '([Cc]lose[sd]|[Ff]ixe[sd]) #(\d+)'

    ## Default project features settings
    default_projects_features:
      issues: true
      merge_requests: true
      wiki: true
      snippets: false
      visibility_level: "private"  # can be "private" | "internal" | "public"

    ## Repository downloads directory
    # When a user clicks e.g. 'Download zip' on a project, a temporary zip file is created in the following directory.
    # The default is 'tmp/repositories' relative to the root of the Rails app.
    # repository_downloads_path: tmp/repositories

  ## External issues trackers
  issues_tracker:

  ## Gravatar
  gravatar:
    enabled: true                 # Use user avatar image from Gravatar.com (default: true)
    # gravatar urls: possible placeholders: %{hash} %{size} %{email}
    # plain_url: "http://..."     # default: http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
    # ssl_url:   "https://..."    # default: https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon

  #
  # 2. Auth settings
  # ==========================

  ## LDAP settings
  ldap:
    enabled: false
    host: '_your_ldap_server'
    port: 636
    uid: 'sAMAccountName'
    method: 'ssl' # "tls" or "ssl" or "plain"
    bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
    password: '_the_password_of_the_bind_user'
    # If you are using "uid: 'userPrincipalName'" on ActiveDirectory you need to
    # disable this setting, because the userPrincipalName contains an '@'.
    allow_username_or_email_login: true
    base: ''
    user_filter: ''

  ## OmniAuth settings
  omniauth:
    # Allow login via Twitter, Google, etc. using OmniAuth providers
    enabled: false
    # CAUTION!
    # This allows users to login without having a user account first (default: false).
    # User accounts will be created automatically when authentication was successful.
    allow_single_sign_on: false
    # Locks down those users until they have been cleared by the admin (default: true).
    block_auto_created_users: true
    providers:

  #
  # 3. Advanced settings
  # ==========================

  # GitLab Satellites
  satellites:
    # Relative paths are relative to Rails.root (default: tmp/repo_satellites/)
    path: ${WORKSPACE}/gitlab-satellites/

  ## Backup settings
  backup:
    path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
    # keep_time: 604800   # default: 0 (forever) (in seconds)

  ## GitLab Shell settings
  gitlab_shell:
    path: ${WORKSPACE}/gitlab-shell/

    # REPOS_PATH MUST NOT BE A SYMLINK!!!
    repos_path: ${WORKSPACE}/repositories/
    hooks_path: ${WORKSPACE}/gitlab-shell/hooks/

    # Git over HTTP
    upload_pack: true
    receive_pack: true

    # If you use non-standard ssh port you need to specify it
    # ssh_port: 22

  ## Git settings
  # CAUTION!
  # Use the default values unless you really know what you are doing
  git:
    bin_path: ${HOME}/.toast/armed/bin/git
    # The next value is the maximum memory size grit can use
    # Given in number of bytes per git object (e.g. a commit)
    # This value can be increased if you have very large commits
    max_size: 5242880 # 5.megabytes
    # Git timeout to read a commit, in seconds
    timeout: 10

  #
  # 4. Extra customization
  # ==========================

  extra:
    ## Google analytics. Uncomment if you want it
    # google_analytics_id: '_your_tracking_id'

    ## Piwik analytics.
    # piwik_url: '_your_piwik_url'
    # piwik_site_id: '_your_piwik_site_id'

    ## Text under sign-in page (Markdown enabled)
    # sign_in_text: |
    #   ![Company Logo](http://www.companydomain.com/logo.png)
    #   [Learn more about CompanyName](http://www.companydomain.com/)

__EOF__

# Configure Charlie the unicorn. ;-)
cat > config/unicorn.rb <<__EOF__
# Sample verbose configuration file for Unicorn (not Rack)

worker_processes 2

working_directory "${WORKSPACE}/gitlab"

listen "${WORKSPACE}/gitlab/tmp/sockets/gitlab.socket", :backlog => 64
listen "127.0.0.1:${INTERNPORT}", :tcp_nopush => true

timeout 30

# feel free to point this anywhere accessible on the filesystem
pid "${WORKSPACE}/gitlab/tmp/pids/unicorn.pid"

stderr_path "${WORKSPACE}/gitlab/log/unicorn.stderr.log"
stdout_path "${WORKSPACE}/gitlab/log/unicorn.stdout.log"

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true


check_client_connection false

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
  # sleep 1
end

after_fork do |server, worker|

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

end

__EOF__

# Config Redis connection.
cat > config/resque.yml <<__EOF__
development: redis://localhost:6379
test: redis://localhost:6379
#production: redis://redis.example.com:6379
production: unix:${HOME}/.redis/sock
__EOF__

# Configure your rack.
cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb

# Production environment.
cp --force config/environments/production.rb config/environments/production.rb.bak
cat > config/environments/production.rb <<__EOF__
Gitlab::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Suppress 'Rendered template ...' messages in the log
  # source: http://stackoverflow.com/a/16369363
  %w{render_template render_partial render_collection}.each do |event|
    ActiveSupport::Notifications.unsubscribe "#{event}.action_view"
  end

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  config_file = Rails.root.join('config', 'resque.yml')

  resque_url = if File.exists?(config_file)
                 YAML.load_file(config_file)[Rails.env]
               else
                 "redis://localhost:6379"
               end
  config.cache_store = :redis_store, {:url => resque_url}, {namespace: 'cache:gitlab'}

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe! unless $rails_rake_task

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.action_mailer.delivery_method = :sendmail
  # Defaults to:
  # # config.action_mailer.sendmail_settings = {
  # #   location: '/usr/sbin/sendmail',
  # #   arguments: '-i -t'
  # # }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.eager_load = true
  config.assets.js_compressor = :uglifier

  config.allow_concurrency = false
end
__EOF__


### GitLab Database ### ########################################################
# Be carefull with "DROP DATABASE" commands!
mysql -e "DROP DATABASE ${USER}_gitlab;"
mysql -e "CREATE DATABASE ${USER}_gitlab CHARACTER SET utf8"
cat > ${WORKSPACE}/gitlab/config/database.yml <<__EOF__
production:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: ${USER}_gitlab
  pool: 10
  username: ${USER}
  password: `my_print_defaults client | grep -- --password | awk -F = '{ print $2 }'`
  # host: localhost
  # socket: /tmp/mysql.sock
__EOF__
chmod o-rwx ${WORKSPACE}/gitlab/config/database.yml


### Gitlab Install ### #########################################################
cd ${WORKSPACE}/gitlab
# CentOS 5? cat /etc/*-release
# Then do also: bundle config build.charlock_holmes --with-icu-dir=/package/host/localhost/icu4c
bundle install --deployment --without development test postgres aws

# Be sure, redis is running and a database exists before doing the setup.
bundle exec rake gitlab:setup RAILS_ENV=production
#	Answer with 'yes' to create db tables.
# 	Ends with:
# 	...
# 	Administrator account created:
# 	
# 	login.........root
# 	password......5iveL!fe


### Gitlab initscript ### ######################################################
# Be aware, this starter is not good to use with Uberspace service.
# Default variables file.
mkdir -p ${HOME}/etc/default
cat > ${HOME}/etc/default/gitlab.default <<__EOF__
RAILS_ENV="production"
app_user="${USER}"
app_root="${WORKSPACE}/gitlab"
pid_path="\$app_root/tmp/pids"
socket_path="\$app_root/tmp/sockets"
web_server_pid_path="\$pid_path/unicorn.pid"
sidekiq_pid_path="\$pid_path/sidekiq.pid"
__EOF__

# GitLab starter.
cp -f ${HOME}/workspace/gitlab/lib/support/init.d/gitlab ${HOME}/bin/gitlab
chmod +x ${HOME}/bin/gitlab
# Change to 'read ${HOME}/etc/default/gitlab.default'.
sed -i -e 's=\/etc\/default\/gitlab=${HOME}\/etc\/default\/gitlab.default=g' ${HOME}/bin/gitlab


### Redirect ### ###############################################################
# Configure web.
mkdir -p /var/www/virtual/${USER}/${DOMAINNAME}
cat > /var/www/virtual/${USER}/${DOMAINNAME}/.htaccess <<__EOF__
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^(.*)$ http://localhost:${INTERNPORT}/\$1 [P]
</IfModule>
# Agains "Can't verify CSRF token authenticity" error.
RequestHeader set X-Forwarded-Proto https
__EOF__


### Check ### ##################################################################
# Last check.
cd ${HOME}/workspace/gitlab
bundle exec rake gitlab:env:info RAILS_ENV=production
bundle exec rake gitlab:check RAILS_ENV=production

pause 'Press [Enter] key to continue... if your are lucky with the tests above. \nAfterwards it is just starting Gitlab. So it will be not a problem to abort this script.'
bundle exec rake assets:precompile RAILS_ENV=production


### Start ### ##################################################################
# This is for what we've done all this stuff above.
cd
gitlab start # start, stop, restart, status


################################################################################
################################################################################
################################################################################


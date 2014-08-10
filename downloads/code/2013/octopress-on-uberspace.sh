#!/bin/bash
# How to setup your uberspace to deploy octopress on github pages.
# No warranty for this script!

githubuser=username
githubreponame=myblog
workingname=$githubreponame
emailadress=your.name@domain.tld
bashconfig=~/.bash_profile #config into bash profile
gemconfig=~/.gemrc

git config --global user.name "username"
git config --global user.email your.name@example.com
echo 'export PATH=/package/host/localhost/ruby-1.9.3/bin:$PATH' >> $bashconfig
echo 'export PATH=~/.gem/ruby/1.9.1/bin:$PATH' >> $bashconfig #not Ruby version, it's API version.
. $bashconfig
exec $SHELL -l
echo 'gem: --user-install --no-rdoc --no-ri' >> $gemconfig
gem update --user-install
echo "Uninstall all rake installations, wich are not 0.9.2.2."
gem uninstall rake
gem install --user-install bundler
mkdir -p ~/workspace
git clone git://github.com/imathis/octopress.git ~/workspace/$workingname
cd ~/workspace/myblog
bundle install --path ~/.gem
rake install
echo "Set your github project at next step: e.g. git@github.com:username/myblog.git"
rake setup_github_pages
ln -s ~/html/$githubreponame ~/workspace/$workingname/public/$githubreponame
rake generate
# Call http://uberspacename.userver.uberspace.de/myblog/
rake deploy
# Call http://username.github.io/myblog/

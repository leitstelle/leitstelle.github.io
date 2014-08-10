#!/bin/bash
# How to setup your uberspace to deploy octopress on github pages.
# No warranty for this script!

# If you have no ssh key:
# run 'ssh-keygen'
# 'cat ~/.ssh/id_rsa.pub'
# Copy this content to your github account.
# -> https://github.com/settings/ssh -> 'Add ssh key'

# You need a github repository for your octopress blog.
# You have to choose:
# 1.) Do you want to deploy on 'username.github.io/reponame'
# 2.) or on 'username.github.io'
# For 1 create a new repo called "reponame"
# For 2 create a new repo called "username.github.io"


# Change here the variables to yours
githubuser=username
githubreponame=reponame 	# Set like 1.) or 2.) above.
emailadress=your.name@domain.tld
workingname=$githubreponame 	# Normaly you can leave this.
bashconfig=~/.bash_profile 	# Normaly you can leave this.
gemconfig=~/.gemrc 		# Normaly you can leave this.


git config --global user.name $githubuser
git config --global user.email $emailadress
echo 'export PATH=/package/host/localhost/ruby-1.9.3/bin:$PATH' >> $bashconfig
echo 'export PATH=~/.gem/ruby/1.9.1/bin:$PATH' >> $bashconfig # Not Ruby version, it's API version.
. $bashconfig
exec $SHELL -l
echo 'gem: --user-install --no-rdoc --no-ri' >> $gemconfig
gem update --user-install
echo "Uninstall all rake installations, wich are not 0.9.2.2."
gem uninstall rake
gem install --user-install bundler
mkdir -p ~/workspace
git clone git://github.com/imathis/octopress.git ~/workspace/$workingname
cd ~/workspace/$workingname
bundle install --path ~/.gem
rake install
echo "Set your github project at next step: e.g. 'git@github.com:username/reponame.git'"
echo "or maybe 'git@github.com:username/username.github.io'"
rake setup_github_pages
echo "If you have option 1.) choosen, you can have a preview bevore you deploy on github."
echo "ln -s ~/html/$githubreponame ~/workspace/$workingname/public/$githubreponame"
rake generate
echo "For option 1.) call http://uberspacename.userver.uberspace.de/$githubreponame/"
rake deploy
echo "For option 1.) call http://$githubuser.github.io/$githubreponame"
echo "For option 2.) call http://$githubuser.github.io"
echo "Sometimes it needs some minutes bevore you can see something there."

# For using your domain.tld for your blog add a file
# mydomain=domain.tld
# echo $mydomain > ~/workspace/$workingname/source/CNAME
# rake generate
# rake deploy
# Add A-Record '204.232.175.78' to your domain.
# AAAA-Record is not available vor github pages. I don't know why.

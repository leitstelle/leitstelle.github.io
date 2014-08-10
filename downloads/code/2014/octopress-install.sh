#!/usr/bin/env bash

GITHUBUSER="zentrale"
GITHUBEMAIL="svc-github@salzkraftwerk.org"
GITHUBPROJECT="git@github.com:leitstelle/leitstelle.github.io.git"
################################################################################

git clone https://github.com/imathis/octopress.git leitstelle.github.io

cd leitstelle.github.io

git config user.name ${GITHUBUSER}
git config user.email ${GITHUBEMAIL}
rbenv local 2.1.2
gem install bundler

mkdir .bundle
cat > .bundle/config <<__EOF__
---
BUNDLE_PATH: vendor/bundle
BUNDLE_DISABLE_SHARED_GEMS: '1'
__EOF__
echo "You need to pre add to every command 'bundle exec'"
echo "E.g. 'bundle exec rake generate'"
exho "So bundle manage the local installation of gems."

bundle install
bundle exec rake install


echo "Set your github project at next step: e.g. 'git@github.com:username/reponame.git'"
echo "or maybe 'git@github.com:username/username.github.io'"
bundle exec rake setup_github_pages

# Create preview symbolic link
rm -rf public && ln -s ../../html/leitstelle-preview public

echo "If you have option 1.) choosen, you can have a preview bevore you deploy on github."
echo "ln -s ~/html/$githubreponame ~/workspace/$workingname/public/$githubreponame"
bundle exec rake generate

echo "For option 1.) call http://uberspacename.userver.uberspace.de/$githubreponame/"
bundle exec rake deploy

echo "For option 1.) call http://$githubuser.github.io/$githubreponame"
echo "For option 2.) call http://$githubuser.github.io"
echo "Sometimes it needs some minutes bevore you can see something there."



### PLUGINS ###
# https://github.com/imathis/octopress/wiki/3rd-party-plugins
# https://github.com/optikfluffel/octopress-responsive-video-embed.git

### Theme ###

# For using your domain.tld for your blog add a file
# mydomain=domain.tld
# echo $mydomain > ~/workspace/$workingname/source/CNAME
# rake generate
# rake deploy
# Add A-Record '204.232.175.78' to your domain.
# AAAA-Record is not available vor github pages. I don't know why.


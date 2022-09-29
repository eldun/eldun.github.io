#!/bin/bash
 
 
if [ $(basename $PWD) != eldun.github.io ]
then
    exit "Please execute 'update-live-site.sh' from the site's root directory"
fi
 
git checkout source
 
# Generate site from branch 'source'
bundle exec jekyll build
 
git checkout master
 
# Move all generated files in _site to root directory 
mv -r _site/* .
 
git push

git checkout source

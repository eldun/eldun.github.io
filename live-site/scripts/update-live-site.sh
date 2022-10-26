#!/bin/bash
 
 
if [ $(basename $PWD) != eldun.github.io ]
then
    exit "Please execute 'update-live-site.sh' from the site's root directory"
fi
 
git checkout source
 
# Generate site from branch 'source'
bundle exec jekyll build

# Create a add directory 'live-site' which of branch 'master'
git worktree add live-site master
 
# Move all generated files in _site to root directory of live site (mv doesn't have a recursive option, so I'm using cp)
cp -r _site/* live-site
rm -r _site

cd live-site
git add *
git commit -m "Update live site from branch 'source'"
git push

cd ..
git worktree remove live-site/

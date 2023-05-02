- Set up spellchecker / broken link checker
- Find a better solution automatically changing '<' to '&lt;' within <pre> tags
- Add post comments
- Floating + current position for table of contents
- Add permalink icons next to headers
- Automatically insert <hr> elements before headers
- Remove build conflicts / warnings
- Add instructions to fix `bundle install` issues to website blog post:
    - bundle `install`
    - Try to `gem install` whatever is needed
    - If that doesn't work, try using `gem install gem_name --user-install`
    - If you get a warning that ruby bin is not in your PATH, add ruby to your path in your .bash_profile[helpful link on correctly adding to path](https://unix.stackexchange.com/questions/26047/how-to-correctly-add-a-path-to-path):
        PATH=$PATH:/home/evan/.gem/ruby/3.0.0/bin

    - If that doesn't work, [there is probably a gemfile.lock file that freezes all the versions at what was originally in the gemfile. Try deleting the lock file.](https://talk.jekyllrb.com/t/bundler-could-not-find-compatible-versions-for-gem-jekyll/6275/3)    
    - [This is probably the issue I keep running into](https://stackoverflow.com/a/42844361/13569456): 
    > Usually if you're using RVM, rbenv or chruby to install Ruby, all the gems will be installed in your home folder under ~/.rbenv/ruby-version/...
    > 
    > If you're using your system Ruby though (the one that is installed by default) the gems are installed alongside it in a location that you don't have access to without sudo.
    > 
    > My guess would be that your version manager defaults to the system Ruby but some of your projects have a .ruby-version file in them that tells it to use a different version of Ruby which you have access to.

    - SO - Install rbenv, get a clean version of the repo, and `bundle install`, entering your password if needed.

- Pagination
- Dark / light themes
- Add fontawesome icons to the beginnings of highlights
- Update description in google search results
- Ensure tab titles are logical
- Use flexbox for post tags and nav bar and whatever else
- Fix tag page links
- Redesign image sources (float them on the bottom right of the image)
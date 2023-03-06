- Set up spellchecker / broken link checker
- Find a better solution automatically changing '<' to '&lt;' within <pre> tags
- Add post comments
- Floating / highlighted table of contents
- Add permalinks next to headers
- Automatically insert <hr> elements before headers
- Remove build conflicts / warnings
- Add instructions to fix `bundle install` issues to website blog post:
    - bundle `install`
    - Try to `gem install` whatever is needed
    - If that doesn't work, try using `gem install gem_name --user-install`
    - If you get a warning that ruby bin is not in your PATH, add ruby to your path in your .bash_profile[helpful link on correctly adding to path](https://unix.stackexchange.com/questions/26047/how-to-correctly-add-a-path-to-path):
        PATH=$PATH:/home/evan/.gem/ruby/3.0.0/bin

    - If that doesn't work, [there is probably a gemfile.lock file that freezes all the versions at what was originally in the gemfile. Try deleting the lock file.](https://talk.jekyllrb.com/t/bundler-could-not-find-compatible-versions-for-gem-jekyll/6275/3)
    - run bundle install,entering your password if needed.
- Pagination
- Dark / light themes
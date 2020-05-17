# frozen_string_literal: true

source "https://rubygems.org"
ruby RUBY_VERSION

# We'll need rake to build our site in TravisCI
gem "rake", "~> 12"
gem "jekyll"

# Optional: Add any custom plugins here.
# Some useful examples are listed below
group :jekyll_plugins do
  gem "jekyll-feed"
  gem "jekyll-sitemap"
  gem "jekyll-paginate-v2"
  gem "jekyll-seo-tag"
  gem "jekyll-redirect-from"
end

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "jekyll-theme-cayman"
gem "jekyll-include-cache"


# gem "rails"

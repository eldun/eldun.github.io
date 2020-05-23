---
title: "Building a Blog:"
subtitle: "Howdy!"
layout: post
author: Evan
header-image: /assets/images/blog-images/howdy/howdy.png
header-image-alt: Howdy!
header-image-title: howdy, partner.
tags: web jekyll github-pages ruby
---

<a id="continue-reading-point"></a>
They say the best time to start a technical blog is twenty years ago, and that the second best time is today. Continue reading to learn about my site and the hurdles I faced building it.

<!--end-excerpt-->
---

## Contents

<ul class="table-of-contents">
<li><a href="#humble-beginnings">Humble Beginnings</a></li>
<li><a href="#github-pages">GitHub Pages</a></li>
<li><a href="#jekyll">Jekyll</a></li>
<li><a href="#custom-ruby-plugins">Custom Ruby Plugins</a></li>
<li><a href="#archive-page">Archive Page</a></li>
<li><a href="#tag-system">Tag System</a></li>
<li><a href="#search-function">Search Function</a></li>
<li><a href="#the-future">The Future</a></li>
</ul>

---

## <a id="humble-beginnings"></a>Humble Beginnings
I really decided on building a blog when I started working on Peter Shirley's [Ray Tracing in One Weekend](https://raytracing.github.io/) series. As excellent as the content is, some of the explanations and illustrations are a bit muddy. Searching for additional resources led me to [Victor Li's Blog](http://viclw17.github.io/). Inspired by the clarity, variety, and layout of Victor's blog, I constructed a similar site for myself to document my work and personal excursions as a developer.

---

## <a id="github-pages"></a>GitHub Pages

As you may have surmised from the URL, this site is hosted by GitHub Pages. Originally, I was going to register a domain from Hostinger, but GitHub Pages is FREE. Additionally, GitHub is probably the most sensible place to expand my portfolio, and a static site is all I really needed for a technical blog... for now.

The only real trouble I ran into was trying to use custom plugins. More on this issue and how I went about solving it [below](#ruby-plugins).

---

## <a id="jekyll"></a>Jekyll

Straight from Jekyll's GitHub page...

> Jekyll is a simple, blog-aware, static site generator perfect for personal, project, or organization sites. Think of it like a file-based CMS, without all the complexity. Jekyll takes your content, renders Markdown and Liquid templates, and spits out a complete, static website ready to be served by Apache, Nginx or another web server. Jekyll is the engine behind GitHub Pages, which you can use to host sites right from your GitHub repositories.

For the most part, Jekyll has been a breeze to work with. I would recommend it to anyone looking to build a static site.

---

## <a id="custom-ruby-plugins"></a>Custom Ruby Plugins

When constructing the site, this is where I ran into the most trouble. It turns out that when using the github-pages gem, the site is generated in safe mode and the plugins directory is a random string. Additionally, only a few Jekyll plugins are whitelisted by GitHub Pages. When constructing the tag feature, tags worked fine locally, but when pushing to the master branch, the live site had broken elements. Same with the archive page.

One solution is to build the site locally and push the generated site files to GitHub. In this way, GitHub would interpret the site as static files and not as a Jekyll project - skipping the build process. However, doing so would require a lot of manual file management and would be prone to human error.

The better solution, of course, is to automate. Big thanks to Josh Frankel and [his post](https://joshfrankel.me/blog/deploying-a-jekyll-blog-to-github-pages-with-custom-plugins-and-travisci/) detailing the process.

The basic idea is as follows:
![Workflow for using custom plugins on GitHub Pages](/assets/images/blog-images/howdy/github-pages-build-process.png)

---

- **Create a new branch off of master (in my case, it's called *source*).**

  The _source_ branch is where my changes take place from here on out.
  _Source_ will contain the entire Jekyll project, but master will only contain the static `_site` folder.
  It's also recommended to make _source_ the default branch, as well as protecting it.

- **Generate a GitHub *Personal Access Token* for Travis CI and give it repo scope/access.**

  This will allow Travis CI to perform pushes.

- **Configure the Jekyll site to work with Travis CI.**

  Buckle in, becuase the next part of the process introduces a lot of changes to the Jekyll site.
  
   - **Add the following to the `Gemfile`:**
      
      ``` 
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
      gem "jekyll-compose", "~> 0.5"
      gem "jekyll-redirect-from"
      end
      ```
  - **Ensure any Gemfiles used in the Gemfile are in `_config.yml` as well.**

  - **Exclude certain files to ensure they don't end up in *master* after Travis CL builds *source*.**

  - **Sample `_config.yml`:**

    ```
    title: Your blog title
    email: your.email@gmail.com

    # many other settings
    # ...

    # Any plugins within jekyll_plugin group from Gemfile
    plugins:
    - jekyll-feed
    - jekyll-sitemap
    - jekyll-paginate-v2
    - jekyll-seo-tag
    - jekyll-compose
    - jekyll-redirect-from

    # Exclude these files from the build process results.
    # Prevents them from showing up in the master branch which 
    # is the live site.
    exclude:
    - vendor
    - Gemfile
    - Gemfile.lock
    - LICENSE
    - README.md
    - Rakefile
    ```    
  - **Since *master* will be used to display the static site, we need git to ignore changes to `_site`. Add the following to `.gitignore`:**

    ```
    .sass-cache
    .jekyll-metadata
    _site
    ```

  - **A `.travis.yml` file is needed to inform Travis CI how to run:**

    ```
    #All of this together basically says, “Using the source branch from this repo, push all the files found within the site directory to the master branch of the repo”.
    
    language: ruby #Use Ruby
    rvm: 
        - 2.3.1 #Use RVM to set ruby version to 2.3.1
    install:
        - bundle install #Run bundle install to install all gems.
    deploy:
        provider: pages #Use TravisCI’s Github Pages provider
        skip_cleanup: true #Preserve files created during build phase.
        github_token: $GITHUB_TOKEN # Our personal access token. This is currently a reference to an environment variable which will be added in the TravisCI setup section below.
        local_dir: _site #Use all files found in this directory for deployment.
        target_branch: master #Push resulting build files to this branch on Github.
    on:
        branch: source #Only run TravisCI for this branch.
    ```
    
  - **The `.travis.yml` only works by using the following `Rakefile` to manually build the site:**
    
    ```
    # filename: Rakefile
    task :default do
    puts "Running CI tasks..."

    # Runs the jekyll build command for production
    # TravisCI will now have a site directory with our
    # statically generated files.
    sh("JEKYLL_ENV=production bundle exec jekyll build")
    puts "Jekyll successfully built"
    end
    ```

  - **The `Rakefile` runs on every build. All checks must be passed before Travis CI will deploy the build.**

  - **Set up Travis CI.**

    Sign in to Travis CI.
    Find the appropriate repository and enable it.
    Create a new environment variable named `GITHUB_TOKEN` from the repository settings page and enter the *Personal Access Token* from way back when.

  - **Cross fingers and PUSH (to *source*).**

The Travis CI build should start, complete, and the site will be live!

WOW! Quite a bit of work for some custom plugins! Namely, my archive page and tag system. Again, HUGE thanks to [Josh Frankel](https://joshfrankel.me) for [his post](https://joshfrankel.me/blog/deploying-a-jekyll-blog-to-github-pages-with-custom-plugins-and-travisci/)!

---

## <a id="archive-page"></a>Archive Page
The archive page I have on my site at the time of this post is adapted from [Sodaware's Repository](https://github.com/Sodaware/jekyll-archive-page). There's not much to it, just some basic ruby data collection and a simple layout file. I would eventually like to style it in a way that is more pleasing on mobile devices.

---

## <a id="tag-system"></a>Tag System
For post tagging, I followed an [example from Lunar Logic](https://blog.lunarlogic.io/2019/managing-tags-in-jekyll-blog-easily/). In the Lunar Logic post, the author, [Anna Ślimak](https://blog.lunarlogic.io/author/anna/), details using Jekyll hooks - which allow for fine-grained control over various aspects of the build process. For example, one could execute custom functionality every time Jekyll renders a post. That's exactly what I'm doing on my site for the tags.

While tags can simply be entered in the Front Matter of posts, no html is generated for that specific tag.I could manually create a file for said tag in the tags directory, but the hook automatically does that work for me.

Here's the code:
```
Jekyll::Hooks.register :posts, :post_write do |post|
    all_existing_tags = Dir.entries("tags")
      .map { |t| t.match(/(.*).md/) }
      .compact.map { |m| m[1] }
  
    tags = post['tags'].reject { |t| t.empty? }
    tags.each do |tag|
      generate_tag_file(tag) if !all_existing_tags.include?(tag)
    end
  end
  
  def generate_tag_file(tag)
    File.open("tags/#{tag}.md", "wb") do |file|
      file << "---\nlayout: tag-page\ntag: #{tag}\n---\n"
    end
  end
```
---

## <a id="search-function"></a>Search Function
The search function was adapted from [Christian Fei's Simple Jekyll Search](https://github.com/christian-fei/Simple-Jekyll-Search). Here's the rundown:

Jekyll is all client-side, so the required content for a search must be stored in a file on the site itself.

Within the root of the Jekyll project, a `.json` file is created from existing posts containing data to search through:

<a id="search-json"></a>`/search.json`:
```
{% raw %}
---
---
[
  {% for post in site.posts %}
    {

      "title"    : "{{ post.title | escape }}",
      "tags"     : "{{ post.tags | join: ', ' }}",
      "date"     : "{{ post.date }}",
      "url"      : "{{ site.baseurl }}{{ post.url }}"

    } {% unless forloop.last %},{% endunless %}
  {% endfor %}
]
```
{% endraw %}

This code generates a `search.json` file in the `_site` directory. Don't forget to add escape characters to prevent the `.json` file from getting messed up. [Liquid has some useful filters that can help out](https://shopify.github.io/liquid/). Here's a snippet of my generated `search.json`:

```
[
    {

      "title"    : "Howdy",
      "tags"     : "web, jekyll, github-pages, ruby",
      "date"     : "2020-05-18 00:00:00 -0400",
      "url"      : "/2020/05/18/howdy.html"

    } ,
...
```

If we wanted to include other aspects of the post in our search, such as the excerpt, content, or custom variables, we could easily follow the [template above](#search-json).

Save the [search script](https://github.com/christian-fei/Simple-Jekyll-Search/blob/master/dest/simple-jekyll-search.js) in `/js/simple-jekyll-search.js`.

I placed the necessary HTML elements for the search function inside `/_includes/search-bar.html`:

```
<!-- Html Elements for Search -->
<div id="search-container" style="visibility: hidden;">
  <input type="text" id="search-input" placeholder="Search..." />
  <ul id="results-container"></ul>
</div>

<!-- Script pointing to search-script.js -->
<script src="/js/search-script.js" type="text/javascript"></script>

<!-- Configuration -->
<script>
  SimpleJekyllSearch({
    searchInput: document.getElementById('search-input'),
    resultsContainer: document.getElementById('results-container'),
    json: '/search.json',
    searchResultTemplate: '<li><a href="{{ site.url }}{url}">{title}</a></li>'
  })
  </script>

```
 and included it right below the nav bar in `/_layouts/default.html`.

 The `searchResultTemplate` variable above determines what is included in the dropdown search results.

 Lastly, I added some javascript to toggle the search bar from visible to hidden.

---

## <a id="the-future"></a>The Future
From here onwards, I plan to document as concisely and as compellingly every personal project I undertake.

Oh, and to reformat my `style.css`. It's a little sloppy.
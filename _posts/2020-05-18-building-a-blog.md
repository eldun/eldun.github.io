---
title: "Building a Blog:"
subtitle: "Howdy!"
excerpt: "They say the best time to start a technical blog is twenty years ago, and that the second best time is today. Continue reading to learn about my site and the hurdles I faced building it."
toc: true
layout: post
author: Evan
# header-image: /assets/images/blog-images/howdy/howdy.png
# header-image-alt: Howdy!
# header-image-title: howdy, partner.
tags: web jekyll github-pages ruby
---




<!-- <ul class="table-of-contents">
<li><a href="#humble-beginnings">Humble Beginnings</a></li>
<li><a href="#github-pages">GitHub Pages</a></li>
<li><a href="#jekyll">Jekyll</a></li>
<li><a href="#custom-ruby-plugins">Custom Ruby Plugins</a></li>
<li><a href="#archive-page">Archive Page</a></li>
<li><a href="#tag-system">Tag System</a></li>
<li><a href="#search-function">Search Function</a></li>
<li><a href="#the-future">The Future</a></li>
<li><a href="#updates">Updates</a></li>
</ul> -->


## Humble Beginnings
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

<span class="highlight-yellow">Update: "Since June 15th, 2021, the building on travis-ci.org is ceased. Please use travis-ci.com from now on." This includes a brand new subscription fee! And re-configuring!<br>I don't feel like dealing with that (or looking into other options right now), so for the time being, I'll just be `jekyll build`-ing `source` and pushing the updated directory `_site` to `master`.</span>

<span class="highlight-yellow">Update(Sep 2022): I wrote a little bash script to update the live site from the source branch. Git worktree is a neat feature! I've never used it before. Here's the script:

<pre><code class="language-bash">
#!/bin/bash
 
 
if [ $(basename $PWD) != eldun.github.io ]
then
    exit "Please execute 'update-live-site.sh' from the site's root directory"
fi
 
git checkout source
 
# Generate site from branch 'source'
bundle exec jekyll build

# Create a add directory 'live-site' which is essentially branch 'master'
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
</code></pre>
</span>

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

      <pre><code class="language-ruby">source "https://rubygems.org"
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
      end</code></pre>

  - **Ensure any Gemfiles used in the Gemfile are in `_config.yml` as well.**

  - **Exclude certain files to ensure they don't end up in *master* after Travis CI builds *source*.**

  - **Sample `_config.yml`:**

    <pre><code class="language-yaml">title: Your blog title
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
    - Rakefile</code></pre>

  - **Since *master* will be used to display the static site, we need git to ignore changes to `_site`. Add the following to `.gitignore`:**

    <pre><code class="language-git">.sass-cache
    .jekyll-metadata
    _site</code></pre>

  - **A `.travis.yml` file is needed to inform Travis CI how to run:**

    <pre><code class="language-yaml">#All of this together basically says, “Using the source branch from this repo, push all the files found within the site directory to the master branch of the repo”.

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
        branch: source #Only run TravisCI for this branch.</code></pre>

  - **The `.travis.yml` only works by using the following `Rakefile` to manually build the site:**

    <pre><code class="language-ruby"># filename: Rakefile
    task :default do
    puts "Running CI tasks..."

    # Runs the jekyll build command for production
    # TravisCI will now have a site directory with our
    # statically generated files.
    sh("JEKYLL_ENV=production bundle exec jekyll build")
    puts "Jekyll successfully built"
    end</code></pre>

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

While tags can simply be entered in the Front Matter of posts, no html is generated for that specific tag. I could manually create a file for said tag in the tags directory, but the hook automatically does that work for me.

Here's the code:
<pre><code class="language-ruby">Jekyll::Hooks.register :posts, :post_write do |post|
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
  end</code></pre>

---

## <a id="search-function"></a>Search Function
The search function was adapted from [Christian Fei's Simple Jekyll Search](https://github.com/christian-fei/Simple-Jekyll-Search). Here's the rundown:

Jekyll is all client-side, so the required content for a search must be stored in a file on the site itself.

Within the root of the Jekyll project, a `.json` file is created from existing posts containing data to search through:

<a id="search-json"></a>`search.json`:
<pre><code class="language-json">{% raw %}---
---
[
  {% for post in site.posts %}
    {

      "title"    : "{{ post.title | escape }}",
      "subtitle"    : "{{ post.subtitle | escape }}",
      "tags"     : "{{ post.tags | join: ', ' }}",
      "date"     : "{{ post.date }}",
      "url"      : "{{ site.baseurl }}{{ post.url }}"

    } {% unless forloop.last %},{% endunless %}
  {% endfor %}
]</code></pre>

{% endraw %}

This code generates a `search.json` file in the `_site` directory. Don't forget to add escape characters to prevent the `.json` file from getting messed up. [Liquid has some useful filters that can help out](https://shopify.github.io/liquid/). Here's a snippet of my generated `search.json`:

<pre><code class="language-json">...
{

      "title"    : "Building a Blog:",
      "subtitle"    : "Howdy!",
      "tags"     : "web, jekyll, github-pages, ruby",
      "date"     : "2020-05-18 00:00:00 -0400",
      "url"      : "/2020/05/18/building-a-blog.html"

    } 
...</code></pre>


If we wanted to include other aspects of the post in our search, such as the excerpt, content, or custom variables, we could easily follow the [template above](#search-json).

Save the [search script](https://github.com/christian-fei/Simple-Jekyll-Search/blob/master/dest/simple-jekyll-search.js) in `/js/simple-jekyll-search.js`.

I placed the necessary HTML elements for the search function inside `/_includes/search-bar.html`:

<pre><code class="language-html">&lt;!-- Html Elements for Search -->
&lt;div id="search-container" style="visibility: hidden;">
  &lt;input type="text" id="search-input" placeholder="Search..." />
  &lt;ul id="results-container">&lt;/ul>
&lt;/div>

&lt;!-- Script pointing to search-script.js -->
&lt;script src="/js/site-scripts/search-script.js" type="text/javascript">&lt;/script>

&lt;!-- Configuration -->
&lt;script>
  SimpleJekyllSearch({
    searchInput: document.getElementById('search-input'),
    resultsContainer: document.getElementById('results-container'),
    json: '/search.json',
    searchResultTemplate: '&lt;li>&lt;a href="{{ site.url }}{url}">{title}&lt;/a>&lt;/li>'
  })</script></code></pre>
  
 and included it right below the nav bar in `/_layouts/default.html`.

 The `searchResultTemplate` variable above determines what is included in the dropdown search results.

 Lastly, I added some javascript to toggle the search bar from visible to hidden.

---

## <a id="the-future"></a>The Future
From here onwards, I plan to document as concisely and as compellingly as possible every personal project I undertake.

Oh, and to reformat my `style.css`. It's a little sloppy.

<hr>

## <a id="updates"></a>Updates

### <time>2021-04</time>

<details>
<summary>Refactored my CSS into multiple files</summary>
<br>
I used to have one monolithic style.scss file. After some refactoring, this is the result:
<pre><code class="language-treeview">eldun.github.io/
    ├── assets/
    │   ├── css/
    │   │   └── style.scss
    │   ├── images/
    │   └── webfonts/
    ├── _sass/
    │   ├── fontawesome/
    │   └── site/
    │       ├── about-me.scss
    │       ├── archive.scss
    │       ├── header.scss
    │       ├── images.scss
    │       ├── mathjax.scss
    │       ├── nav.scss
    │       ├── post-navigation.scss
    │       ├── posts.scss
    │       ├── search.scss
    │       └── tags.scss
    └── ...</code></pre>

<code>style.scss</code> is now mostly imports and high-level stylings:
<pre><code class="language-scss">{%raw%}---
---
$color-primary: {{ site.data.colors["primary"]["dark-theme"] }};
$color-secondary:  {{ site.data.colors["secondary"]["dark-theme"] }};
$color-accent: {{ site.data.colors["accent"]["dark-theme"] }};
$color-clickable: {{ site.data.colors["clickable"]["dark-theme"] }};
$color-text: {{ site.data.colors["text"]["dark-theme"] }};

/* This file extends/overrides the CSS file used by "jekyll-theme-cayman" (_site/assets/css/style.css)
  https://help.github.com/en/github/working-with-github-pages/adding-a-theme-to-your-github-pages-site-using-jekyll#customizing-your-themes-css 
*/


// I took this out for a second, but putting it back in is easier than writing a bunch of responive css
@import "jekyll-theme-cayman";

// The default folder for scss files is _sass (this can be changed in config.yml)
// Was having a lot of trouble trying to use fontawesome icons with their relative paths
// before creating the_sass directory and moving the scss files there.
@import "fontawesome/fontawesome.scss";
@import "fontawesome/solid.scss";
@import "fontawesome/brands.scss";
@import "fontawesome/regular.scss";


@import "site/header.scss";
@import "site/nav.scss";

@import "site/posts.scss";
@import "site/post-navigation.scss";
@import "site/images.scss";

@import "site/mathjax.scss";

@import "site/about-me.scss";
@import "site/archive.scss";
@import "site/tags.scss";
@import "site/search.scss";

// CSS rules here{%endraw%}</code></pre>
</details>
  
<details>
<summary>Started using <a class="btn" href="https://prismjs.com/" target="_blank">Prism Syntax highlighter</a>
</summary>
<br>
All I had to do was generate js and css files from their site, plop them into my site directory, and link 'em. To use a specific language, all I need to do is specify a code block like so:
<code>&lt;pre>&lt;code class="language-xxxx"></code>
<pre><code class="language-treeview">eldun.github.io
    ├── assets/
    │   ├── css/
    │   │   └── style.scss // import generated prism css here
    │   ├── images/
    │   └── webfonts/
    ├── _config.yml
    ├── _data/
    ├── downloads/
    ├── _drafts/
    ├── Gemfile
    ├── Gemfile.lock
    ├── _includes/
    ├── index.md
    ├── js/
    │   ├── post-scripts/
    │   └── site-scripts/
    │       ├── prism.js // generated by prism
    │       ├── search-script.js
    │       ├── toggle-search.js
    │       └── vanilla-back-to-top.min.js
    ├── _layouts/
    │   ├── archive-page.html
    │   ├── default.html // link to generated prism js here 
    │   ├── post.html
    │   └── tag-page.html
    ├── _plugins/
    ├── _posts/
    ├── Rakefile
    ├── _sass/
    │   ├── fontawesome/
    │   └── site/
    │       ├── about-me.scss
    │       ├── archive.scss
    │       ├── header.scss
    │       ├── images.scss
    │       ├── mathjax.scss
    │       ├── nav.scss
    │       ├── post-navigation.scss
    │       ├── posts.scss
    │       ├── prism.scss // generated by prism
    │       ├── search.scss
    │       └── tags.scss
    └── ...</code></pre>
</details>

### <time>2022-08</time>

<details>

<summary>
Dynamic (& prettier) Table of Contents
</summary>
<br>


Manual tables of content are time intensive and prone to authoring errors, I've come to find. Thankfully there's a <a href='https://stackoverflow.com/a/5233948'>gem</a> for <a href='https://github.com/toshimaru/jekyll-toc'>generating a 'toc' dynamically</a>, so I don't have to do too much work.

The instructions are as follows:
<img src="/assets/images/blog-images/howdy/jekyll-toc-install.png">

After following these steps, I only need to change a few things in <code>_layouts/post.html`</code>:
<pre><code class='language-diff-markup diff-highlight'>
{% raw %}
&lt;div class="post-header inactive"&gt;
&lt;h1 id="post-title"&gt;{{ page.title }}&lt;/h1&gt;
&lt;h3 id="post-subtitle"&gt;{{ page.subtitle }}&lt;/h3&gt;
&lt;div class="post-date"&gt;
    &lt;i class="fas fa-calendar"&gt;&lt;/i&gt; &lt;time&gt;{{ page.date | date_to_string }}&lt;/time&gt;
&lt;/div&gt;
&lt;/div&gt;

&lt;img src="{{ page.header-image }}" alt="{{ page.header-image-alt }}" title="{{ post.header-image-description }}"&gt;

+ &lt;div class='table-of-contents'&gt;{{ content | toc_only }}&lt;/div&gt;

+ {{ content | inject_anchors }}

&lt;hr&gt;
&lt;h1&gt;&lt;i class="fas fa-hand-peace"&gt;&lt;/i&gt;&lt;/h1&gt;
&lt;div class="post-tags"&gt;
    {% include post-tags.html %}
&lt;/div&gt;

{% endraw %}
</code></pre>

Now I can just use regular headers instead of clumsy anchors, and my table of contents will be generated automatically.

</details>

<details>

<summary>
Add the ability to use Liquid in Front Matter
</summary>
<br>

I've started putting more of my post content into the [Front Matter](https://jekyllrb.com/docs/front-matter/) and letting my layout do most of the work. You can't natively use [Liquid](https://jekyllrb.com/docs/liquid/) in Front Matter, but there's a <a href='https://github.com/gemfarmer/jekyll-liquify'>gem</a> for enabling such functionality.

</details>

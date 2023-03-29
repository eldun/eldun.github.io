# Generate pages for post tags automatically in the "tags" folder.

# NOTE #
# Following the example at https://blog.lunarlogic.io/2019/managing-tags-in-jekyll-blog-easily/,
# tags were being generated in the "_tags" folder. However, tags could not be found when
# clicking on the links in a blog post. I tried changing the href within posts, 
# the permalink in navigation.yml, all sorts of things.
# The only solution I found was to generate the .md files in "tags" instead of "_tags." 
# I don't know why it works and _tags doesn'. The important thing is that it works.


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
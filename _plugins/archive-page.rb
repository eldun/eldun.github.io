# Modified from https://github.com/Sodaware/jekyll-archive-page
# jekyll-archive-page - A simple archive plugin for Jekyll
# Copyright (C) 2013 Phil Newton

# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.  





##
# Generates the "/blog/archives/" page
#
# Requires the "archive-page.html" template

module Jekyll
  
  ##
  # Custom page purely for archives
  class ArchivePage < Page
    
    ##
    # Initialize archives page
    def initialize(site, base)
      
      @site = site
      @base = base
    #   @dir  = site.config['archive_path']
      @name = 'archive.html'
      
      self.process(@name)
      
      # Read the YAML data from the layout page.
      self.read_yaml(File.join(base, '_layouts'), 'archive-page.html')
      
      # Setup the title (if not set?)
      self.data['title'] = "Archives"
      
      # Grab the data we need:
      #   - A list of all years that contain posts
      #   - A list of all months that contain posts
      #   - A list of all posts, grouped by date (or we can do this in the template?)
      self.data['grouped_posts']       = self.get_grouped_posts
      self.data['years']               = self.data['grouped_posts'].keys
      self.data['month_abbreviations'] = Date::ABBR_MONTHNAMES
      self.data['month_names']         = Date::MONTHNAMES

      # page.archives
      #   [2001]
      #   [01] => array of posts
      #   
      #
      
    end
    
    def get_grouped_posts

      # Get date of first post
      start_year = site.posts.docs.first.data['date'].year
      end_year   = Date.today.year

      years      = (start_year..end_year).to_a
      post_map   = {}

      years.each do |year| 
        post_map[year] = Hash.new

        (1..12).each do |month| 
          post_map[year][month] = Array.new
        end
      end

      # Add each post
      site.posts.docs.each do |post|
        post_map[post.data['date'].year][post.data['date'].month] << post
      end

      return post_map

    end
    
  end
  
  class ArchivePageGenerator < Generator
    
    safe true
    priority :low
    
    ##
    # Generate 
    def generate(site)
      
      # Check for template
      throw "No 'archive-page' layout found." if !site.layouts.key? 'archive-page'
      
      # Grab data
      
      # Build the page and add
      archives = ArchivePage.new(site, site.source)
      archives.render(site.layouts, site.site_payload)
      archives.write(site.dest)
      site.pages << archives
      
    end

  end
    
end
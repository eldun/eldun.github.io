---
layout: default
title: Home
---
<h2>Blog</h2>
<ul style="list-style-type: none;">
  {% for post in site.posts %}
  <hr>
    <li>
      <h3 style="text-align: center">
      <a href="{{ post.url }}">{{ post.title }}
      </a></h3>
      <div class="post-date">
      <i class="fas fa-calendar"></i> <time>{{ post.date |date_to_string }}</time>
      </div>
      <img src="{{ post.header-image }}" alt="{{ post.header-image-description }}">
      <p>{{ post.excerpt }}</p>

      <div class="post-button">
      <a href="{{ post.url }}" class="btn">Continue reading»</a>
      </div>
    </li>
  {% endfor %}
</ul>
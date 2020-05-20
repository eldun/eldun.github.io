---
layout: default
title: Home
---
<ul style="list-style-type: none;">
  {% for post in site.posts %}
  <hr>
    <li>
      <h1 style="text-align: center">
      <a href="{{ post.url }}#post-title">{{ post.title }}
      </a></h1>
      <div class="post-date">
      <i class="fas fa-calendar"></i> <time>{{ post.date |date_to_string }}</time>
      </div>
      <img src="{{ post.header-image }}" alt="{{ post.header-image-alt }}" title="{{ post.header-image-title }}">

      {{ post.excerpt }}

      <div class="post-button">
      <a href="{{ post.url }}#continue-reading-point" class="btn">Continue reading»</a>
      </div>
    </li>
  {% endfor %}
</ul>
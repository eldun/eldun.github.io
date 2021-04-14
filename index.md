---
layout: default
title: Home
---
<ul class="post-list">
{% for post in site.posts %}
<li class="post">
  <a href="{{ post.url }}#post-title" class="post-header">
    <div>
      <h1> {{ post.title }}</h1>
      <h3> {{ post.subtitle }}</h3>
    </div>
  </a>
  <div class="post-date">
    <i class="fas fa-calendar"></i> <time>{{ post.date | date_to_string }}</time>
  </div>
  <img src="{{ post.header-image }}" alt="{{ post.header-image-alt }}" title="{{ post.header-image-title }}">

  {{ post.excerpt }}

  <div class="post-button">
    <a href="{{ post.url }}#continue-reading-point" class="btn">Continue reading »</a>
  </div>
</li>
<hr>
{% endfor %}
</ul>
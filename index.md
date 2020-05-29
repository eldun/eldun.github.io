---
layout: default
title: Home
---

{% for post in site.posts %}
<hr>
<li>
  <a href="{{ post.url }}#post-title">
    <div>
      <h1 style="color : #cc773f"> {{ post.title }}</h1>
      <h3 style="color : #cc773f"> {{ post.subtitle }}</h3>
    </div>
  </a>
  <div class="post-date">
    <i class="fas fa-calendar"></i> <time>{{ post.date | date_to_string }}</time>
  </div>
  <img src="{{ post.header-image }}" alt="{{ post.header-image-alt }}" title="{{ post.header-image-title }}">

  {{ post.excerpt }}

  <div class="post-button">
    <a href="{{ post.url }}#continue-reading-point" class="btn">Continue reading»</a>
  </div>
</li>

{% endfor %}

</ul>
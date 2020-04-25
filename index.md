---
layout: default
title: dunneev.github.io
---

<ul style="list-style-type: none;">
  {% for post in site.posts %}
    <li>
      <h2 style="text-align: center">
      <a href="{{ post.url }}">{{ post.title }}
      </a></h2>
      <p>{{ post.excerpt }}</p>
    </li>
  {% endfor %}
</ul>
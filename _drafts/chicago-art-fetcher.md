---
title: "Something to Stare At:"
subtitle: "A Highly Configurable Art Fetcher"
use-math: true
use-raw-images: false
layout: post
author: Evan
header-image: /assets\images\blog-images\art-fetcher\the-herring-net-1885.jpg
header-image-alt: Winslow Homer. The Herring Net, 1885. The Art Institute of Chicago.
header-image-title: 
tags: python web
---

<a id="continue-reading-point"></a>
I've had the [same desktop wallpaper](/assets\images\blog-images\art-fetcher\old-desktop-wallpaper.png) for almost ten years. I'd like to change it up. I'd also like to feel like an intellectual. Luckily, the [Art Institute of Chicago](https://www.artic.edu/) and their [API](https://api.artic.edu/docs/) can help me out.

<!--end-excerpt-->

---
## Contents


{% include ray-tracing/part-nav.html %}

<ul class="table-of-contents">
    <li><a href="#the-idea">The Idea</a></li>
        <!-- <ul>
            <li><a href="#adapting-our-ray-class">Adapting our Ray Class</a></li>
            <li><a href="#adapting-our-camera-class">Adapting our Camera Class</a></li>
			<li><a href="#creating-moving-spheres">Creating Moving Spheres</a></li>
            <li><a href="#adapting-our-material-class">Adapting our Material Class</a></li>
            <li><a href="#setting-our-scene">Setting our Scene</a></li>
        </ul>
    <li><a href="#bounding-volume-hierarchies">Bounding Volume Hierarchies</a></li>
		<ul>
            <li><a href="#establishing-a-hierarchy">Establishing a Hierarchy</a></li>
			<li><a href="#implementing-a-hierarchy-using-axis-aligned-bounding-boxes">Implementing a Hierarchy Using Axis-Aligned Bounding Boxes</a></li>
        </ul> -->


</ul>
---

## <a id="the-idea"></a>The Idea

My plan is to create a simple python GUI for automatically downloading and managing images in a folder to be used by Windows' slideshow feature. I'd like to allow the user to perform robust queries with parameters such as:

- time period
- type of art
- predominant color
- popularity
- medium

Additionally, I'll allow the user to control:

- how many images should be in the folder at any time
- how frequently to check for updates
- whatever else feels right


---
title: "Ray Tracing in One Weekend:"
subtitle: "Part Three - The Next Weekend"
use-math: true
use-raw-images: true
layout: post
author: Evan
header-image: /assets\images\blog-images\path-tracer-part-three\
header-image-alt: 
header-image-title: 
tags: graphics ray-tracing ray-tracing-in-one-weekend c++
---

<a id="continue-reading-point"></a>
We've created a [straight-forward ray-tracer]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#post-title) - what more 

<!--end-excerpt-->

<span class="highlight-yellow">
I started this path tracer months ago, and only started this blog in late May. The version of Shirley's book that I used is from some time in 2018 (Version 1.54), and I have found that there is a recently updated version (3.1.2) on [his website](https://raytracing.github.io/) from June 6th, 2020! I also supplemented Shirley's book with [Victor Li's posts on the subject](http://viclw17.github.io/tag/#/Ray%20Tracing%20in%20One%20Weekend). As such, there may be differences in implementation compared to the most recent version of Ray Tracing in One Weekend. <br><br>I am trying to keep things easy-to-follow, mostly sticking with my original code and only changing or adding what I deem to be necessary for readability, clarity, or image rendering purposes. If you are reading this to build your own ray tracer, I highly recommend Shirley's book as a main source.
</span>

---
## Contents


{% include ray-tracing-part-nav.html %}

<ul class="table-of-contents">
    <li><a href="#image-output">Image Output</a></li>
	<li><a href="#timing-execution">Timing Execution</a></li>
	<li><a href="#vec3-class">Vec3 Class</a></li>
	<ul>
	<li><a href="#vector-refresher">Vector Refresher</a></li>
	<li><a href="#vec3-definitions">Vec3 Definitions</a></li>
	</ul>
	<li><a href="#rays">Rays</a></li>
	<ul>
	<li><a href="#sending-rays-from-the-camera">Sending Rays from the Camera</a></li>
	</ul>
	<li><a href="#introducing-spheres">Introducing Spheres</a></li>
	<ul>
	<li><a href="#describing-a-sphere">Describing a Sphere</a></li>
	<li><a href="#placing-a-sphere">Placing a Sphere</a></li>
	</ul>
	<li><a href="#surface-normals">Surface Normals</a></li>
	<ul>
	<li><a href="#simplifying-ray-sphere-intersection">Simplifying Ray-Sphere Intersection</a></li>
	</ul>
	<li><a href="#multiple-spheres">Multiple Spheres</a></li>
	<li><a href="#front-faces-versus-back-faces">Front Faces versus Back Faces</a></li>
	<li><a href="#anti-aliasing">Anti-Aliasing</a></li>
	<ul>
	<li><a href="#adding-anti-aliasing-to-the-camera">Adding Anti-Aliasing to the Camera</a></li>
	</ul>
	<li><a href="#diffuse-materials">Diffuse Materials</a></li>
	<ul>
	<li><a href="#the-math-of-diffuse-materials">The Math of Diffuse Materials</a></li>
	<li><a href="#gamma-correction">Gamma Correction</a></li>
	<li><a href="#shadow-acne">Shadow Acne</a></li>
	<li><a href="#true-lambertian-reflection">True Lambertian Reflection</a></li>
	</ul>
	<li><a href="#common-constants-and-utilities">Common Constants and Utilities</a></li>
	<li><a href="#metal">Metal</a></li>
	<ul>
	<li><a href="#abstract-class-for-materials">Abstract Class for Materials</a></li>
	<li><a href="#describing-ray-object-intersections">Describing Ray-Object Intersections</a></li>
	<li><a href="#light-scatter">Light Scatter</a></li>
	<li><a href="#metal-reflection">Metal Reflection</a></li>
	<li><a href="#adding-metal-spheres-to-the-scene">Adding Metal Spheres to the Scene</a></li>
	<li><a href="#fuzzy-metal">Fuzzy Metal</a></li>
	</ul>
	<li><a href="#dielectrics">Dielectrics</a></li>
	<ul>
	<li><a href="#refraction">Refraction</a></li>
	<li><a href="#snells-law">Snell's Law</a></li>
	<li><a href="#calculating-the-refraction-vector">Calculating the Refraction Vector</a></li>
	<li><a href="#coding-the-refraction-vector">Coding the Refraction Vector</a></li>
	<li><a href="#dielectric-reflections">Dielectric Reflections</a></li>
	<li><a href="#hollow-dielectric-spheres">Hollow Dielectric Spheres</a></li>
	</ul>
	<li><a href="#camera-modeling">Camera Modeling</a></li>
	<li><a href="#depth-of-field">Depth of Field</a></li>
	<li><a href="#final-scene">Final Scene</a></li>
</ul>

---

## <a id="image-output"></a>Image Output

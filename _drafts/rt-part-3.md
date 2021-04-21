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
We've created a [straight-forward ray tracer]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#post-title) - what more could there be to do? By the time we're done with this segment, we'll have what Peter Shirley calls a "real ray tracer".

<!--end-excerpt-->

{% include ray-tracing/disclaimer.html %}

---
## Contents


{% include ray-tracing/part-nav.html %}

<ul class="table-of-contents">
    <li href="#motion-blur">Motion Blur</li>
        <ul>
            <li href="#spacetime-ray-tracing">Space-time Ray Tracing</li>
        </ul>
</ul>

---

## <a id="motion-blur"></a>Motion Blur

Similarly to how we simulated [depth of field] and [imperfect reflections] through brute force in my [previous ray tracing post]({% link _posts/path-tracer/2020-06-19-ray-tracing-in-one-weekend-part-two.md %}), we can also implement motion blur.

[Motion blur] (in a real, physical camera) is a the result of movement while the camera's shutter is open. The image produced is the average of what the camera "saw" over that amount of time.

<span class="captioned-image">
![shutter-speed](./)
[(source)](https://www.studiobinder.com/blog/what-is-shutter-speed/)
</span>


## <a id="spacetime-ray-tracing"></a>Space-time Ray Tracing


Introduction of SpaceTime Ray Tracing subsection
first, we give our ray the ability to store the time at which it exists:

<pre><code class="language-diff-cpp diff-highlight">#ifndef RAYH
#define RAYH
#include "vec3.h"

/*******************************************************************************
* All ray tracers have a ray class, along with what color is seen along a ray.
* A ray can be thought of as the function p(t) = A + t*B ...
* p is a 3d position along a 3d line
* A is the ray origin
* B is the ray direction
* t is a real number, positive or negative. This allows you to traverse the line and face either direction.
* moment is the point in time at which the ray exists.
*******************************************************************************/
class ray
{
public:
	ray() {}
+	ray(const vec3& a, const vec3& b, double moment) { A = a; B = b; mMoment = moment; }
	vec3 origin() const		{ return A; }
	vec3 direction() const	{ return B; }
+	double moment() const  	{ return mMoment; }
	vec3 point_at_parameter(double t) const { return A + t * B; }

	vec3 A;
	vec3 B;
+	double mMoment;
};

#endif // !RAYH</code></pre>


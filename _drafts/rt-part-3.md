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
            <li href="#adapting-our-ray-class">Adapting our Ray Class</li>
            <li href="adapting-our-camera-class">Adapting our Camera Class</li>
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

### <a id="adapting-our-ray-class"></a>Adapting our Ray Class


First, we give our ray the ability to store the time at which it exists.

`ray.h`:

<pre><code class="language-diff-cpp diff-highlight">
  	class ray {
 		public:
 			ray() {}
+			ray(const vec3& a, const vec3& b, double moment) { A = a; B = b; mMoment = moment; }
 			vec3 origin() const		{ return A; }
 	 		vec3 direction() const	{ return B; }
+			double moment() const  	{ return mMoment; }
 			vec3 point_at_parameter(double t) const { return A + t * B; }
 	
  			vec3 A;
  			vec3 B;
+			double mMoment;
 		};</code></pre>


### <a id="adapting-our-camera-class"></a>Adapting our Camera Class

Now we have to update the camera to give each ray a time upon "shooting" one:
`camera.h`:

<pre><code class="language-diff-cpp diff-highlight">
 class camera {
     public:
        camera(vec3 lookFrom, vec3 lookAt, vec3 vUp, double vFov, double aspectRatio,
+	    double aperture, double focusDistance, double shutterOpenTime, double shutterCloseTime) {
        lensRadius = aperture / 2;
        double theta = vFov*pi/180;
        double halfHeight = tan(theta/2);
        double halfWidth = aspectRatio * halfHeight;
        origin = lookFrom;
        w = unit_vector(lookFrom - lookAt);
        u = unit_vector(cross(vUp, w));
        v = cross(w, u);
        lowerLeftCorner = origin
 							- halfWidth * focusDistance * u
                            - halfHeight * focusDistance * v
                            - focusDistance * w;
        horizontal = 2*halfWidth*focusDistance*u;
        vertical = 2*halfHeight*focusDistance*v;
+       this->shutterOpenTime = shutterOpenTime;
+ 		this->shutterCloseTime = shutterCloseTime;
        }
 
        ray get_ray(double s, double t) {
            vec3 rd = lensRadius*random_unit_disk_coordinate();
            vec3 offset = u * rd.x() + v * rd.y();
            return ray(origin + offset,
                        lowerLeftCorner + s*horizontal + t*vertical
                        - origin - offset,
+                       random_double(shutterOpenTime, shutterCloseTime));
         }
 
     private:
        vec3 origin;
        vec3 lowerLeftCorner;
        vec3 horizontal;
        vec3 vertical;
        vec3 u, v, w;
        double lensRadius;
+       double shutterOpenTime;
+       double shutterCloseTime;
 };
 
 #endif // !CAMERAH
</code></pre>
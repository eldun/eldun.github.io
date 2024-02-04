---
title: "Ray Tracing in One Weekend:"
subtitle: "Part Three - The Next Weekend"
excerpt: "We've created a [straight-forward ray tracer]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#post-title) - what more could there be to do? By the time we're done with this segment, we'll have what Peter Shirley calls a \"real ray tracer.\""
use-math: true
use-raw-images: false
toc: true
layout: post
author: Evan
header-image: /assets\images\blog-images\path-tracer-part-three
header-image-alt: 
header-image-title: 
tags: graphics ray-tracing-in-one-weekend c++
---

<a id="continue-reading-point"></a>

{% include ray-tracing/disclaimer.html %}

---
## Contents


{% include ray-tracing/part-nav.html %}



---

## <a id="motion-blur"></a>Motion Blur

Similarly to how we simulated [depth of field]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#depth-of-field) and [imperfect reflections]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#fuzzy-metal) through brute force in my [previous ray tracing post]({% link _posts/path-tracer/2020-06-19-ray-tracing-in-one-weekend-part-two.md %}), we can also implement motion blur.

Motion blur (in a real, physical camera) is a the result of movement while the camera's shutter is open. The image produced is the average of what the camera "saw" over that amount of time.

<span class="captioned-image">
![shutter-speed](/assets/images/blog-images/path-tracer/the-next-week/shutter.webp)
[(source)](https://www.studiobinder.com/blog/what-is-shutter-speed/)
</span>

### <a id="adapting-our-ray-class"></a>Adapting our Ray Class


First, we give our ray the ability to store the time at which it exists.

`ray.h`:

<pre><code class="language-diff-cpp diff-highlight"> 
 class Ray {
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
 };</code></pre>


### <a id="adapting-our-camera-class"></a>Adapting our Camera Class

Now we have to update the camera to give each ray a time upon "shooting" one:
`camera.h`:

<pre><code class="language-diff-cpp diff-highlight">
class camera
	{
	public:
+		camera(vec3 lookFrom, vec3 lookAt, vec3 vUp, double vFov, double aspectRatio, double aperture, double focusDistance, double shutterOpenDuration)
		{
			lensRadius = aperture / 2;
			double theta = vFov * pi / 180;
			double halfHeight = tan(theta / 2);
			double halfWidth = aspectRatio * halfHeight;
			origin = lookFrom;
			w = unit_vector(lookFrom - lookAt);
			u = unit_vector(cross(vUp, w));
			v = cross(w, u);
			lowerLeftCorner = origin - halfWidth * focusDistance * u - halfHeight * focusDistance * v - focusDistance * w;
			horizontal = 2 * halfWidth * focusDistance * u;
			vertical = 2 * halfHeight * focusDistance * v;
+			this->shutterOpenDuration = shutterOpenDuration;
		}

		ray get_ray(double s, double t)
		{
			vec3 rd = lensRadius * random_unit_disk_coordinate();
			vec3 offset = u * rd.x() + v * rd.y();
			return ray(origin + offset,
					lowerLeftCorner + s * horizontal + t * vertical - origin - offset,
+					random_double(0, shutterOpenDuration));
		}

	private:
		vec3 origin;
		vec3 lowerLeftCorner;
		vec3 horizontal;
		vec3 vertical;
		vec3 u, v, w;
		double lensRadius;
+		double shutterOpenDuration;
	};
...
</code></pre>

### <a id="creating-moving-spheres"></a>Creating Moving Spheres

Motion blur would be useless without motion. We can modify our spheres to move linearly from some point `centerStart` to another `centerEnd` starting at `moveStartTime` and stopping at `moveEndTime`. 

`sphere.h`:

<pre><code class="language-diff-cpp diff-highlight"> 
	class sphere : public hittable {
		public:
		sphere() {}
		sphere(vec3 center, float radius, material* material) : 
+			centerStart(center), 
+			centerEnd(center), 
+			moveStartTime(0),
+			moveEndTime(0),
			radius(radius), 
			material_ptr(material){};

+		// Moving sphere
+		sphere(vec3 centerStart, vec3 centerEnd, double timeToTravel, float radius, material &#42;material) : 
+			centerStart(centerStart),
+			centerEnd(centerEnd),
+			moveStartTime(moveStartTime), 
+			moveEndTime(moveEndTime),
+			radius(radius), 
+			material_ptr(material){};

		virtual bool hit(const ray &r, double tmin, double tmax, hit_record &rec) const;

+		vec3 centerAt(double time) const;

+		vec3 centerStart, centerEnd;
+		double moveStartTime, moveEndTime;
		double radius;
		material* material_ptr;
	};
	</code></pre>


Checking for a hit remains mostly the same - we just account for moving spheres by calculating the centers at specific times. If you need a refresher on the implementation details of sphere collisions, check [here]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#simplifying-ray-sphere-intersection). I stray from Shirley's code a small amount here by actually checking if the sphere has moved yet, is moving, or has stopped moving. The result can look a little [goofy](#wait-then-move-sphere), but I like having the option for more interesting motion, and the code feels a bit less ambiguous than Shirley's:
> I’ll create a sphere class that has its center move linearly from center0 at time0 to center1 at time1. Outside that time interval it continues on, so those times need not match up with the camera aperture open and close.  

`sphere.h`:
<pre><code class="language-diff-cpp diff-highlight"> 

	bool sphere::hit(const ray& r, double t_min, double t_max, hit_record& rec) const
	{
+		vec3 oc = r.origin() - centerAt(r.moment()); // Vector from center to ray origin
		double a = r.direction().length_squared();
		double halfB = dot(oc, r.direction());
		double c = oc.length_squared() - radius * radius;
		double discriminant = (halfB * halfB) - (a * c);
		if (discriminant > 0.0) {
			auto root = sqrt(discriminant);

			auto temp = (-halfB - root) / a;

			temp = (-halfB + root) / a;
			if (temp &lt; t_max && temp > t_min) {
				rec.t = temp;
				rec.p = r.point_at_parameter(rec.t);
+				vec3 outward_normal = (rec.p - centerAt(r.moment())) / radius;
				rec.set_face_normal(r, outward_normal);
				rec.material_ptr = material_ptr;
				return true;
			}
		}
		return false;
	}


Vec3 Sphere::centerAt(double time) const {

	// Prevent divide by zero(naN) for static spheres
	if (moveStartTime == moveEndTime) {
		return centerStart;
	}

	else if (time < moveStartTime){
		return centerStart;
	}

	else if (time > moveEndTime){
		return centerEnd;
	}

	else 
		return centerStart + (time * centerVec);
}

</code></pre>

### <a id="adapting-our-material-class"></a>Adapting our Material Class

All calls to our ray constructor within `material.h` must be updated as well:

<pre><code class="language-diff-cpp diff-highlight"> 
class lambertian : public material {
    public:
        lambertian(const vec3& a) : albedo(a){};
        virtual bool scatter(const ray& ray_in, 
                            const hit_record& rec, 
                            vec3& attenuation, 
                            ray& scattered) const {
            vec3 scatter_direction = rec.p + rec.normal + random_unit_vector();
+            scattered = ray(rec.p, scatter_direction - rec.p, ray_in.moment());
            attenuation = albedo;
            return true;
        }
    vec3 albedo; // reflectivity
 };

 // Simulate reflection of a metal (see MetalReflectivity.png)
 // See FuzzyReflections.png for a visualization of fuzziness.
 class metal : public material {
    public:
        metal(const vec3& a, double f) : albedo(a) {
            if (f&lt;1) fuzz = f; else fuzz = 1; // max fuzz of 1, for now.
        }
        virtual bool scatter(const ray& ray_in, 
                            const hit_record& rec, 
                            vec3& attenuation, 
                            ray& scattered) const {
        vec3 reflected = reflect(unit_vector(ray_in.direction()), rec.normal);
+        scattered = ray(rec.p, reflected + fuzz * random_unit_sphere_coordinate(), ray_in.moment()); // large spheres or grazing rays may go below the surface. In that case, they'll just be absorbed.
        attenuation = albedo;
        return dot(scattered.direction(), rec.normal) > 0.0;
    }

    vec3 albedo;
    double fuzz;
 };

class dielectric : public material {
    public:
        dielectric(vec3 a, double ri) : albedo(a), ref_idx(ri) {}

        virtual bool scatter(
            const ray& ray_in, const hit_record& rec, vec3& attenuation, ray& scattered
        ) const {

            attenuation = albedo;

            double n1_over_n2 = (rec.frontFace) ? (1.0 / ref_idx) : (ref_idx);

            vec3 unit_direction = unit_vector(ray_in.direction());
            
            double cosine = fmin(dot(-unit_direction, rec.normal), 1.0);
            double reflect_random = random_double(0,1);
            double reflect_probability;

            vec3 refracted;
            vec3 reflected;

            if (refract(unit_direction, rec.normal, n1_over_n2, refracted)) {
                reflect_probability = schlick(cosine, ref_idx);

                if (reflect_random &lt; reflect_probability) {
                    vec3 reflected = reflect(unit_direction, rec.normal);
+                    scattered = ray(rec.p, reflected, ray_in.moment());
                    return true;
                }
+                scattered = ray(rec.p, refracted, ray_in.moment());
                return true;
            }

            else {
                reflected = reflect(unit_direction, rec.normal);
+                scattered = ray(rec.p, reflected, ray_in.moment());
                return true;
            }

            
        
        }
    public:
        double ref_idx;
        vec3 albedo;
};
</code></pre>

### <a id="using-smart-pointers"></a>Using Smart Pointers

In the time since I've completed [The First Weekend]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html), Shirley has updated his code to use smart pointers in place of raw ones. I should've known to use smart pointers myself, but I was more familiar with java at that time and wanted to stick to the guide.

Anyway, you can read about smart pointers [here](https://docs.microsoft.com/en-us/cpp/cpp/smart-pointers-modern-cpp). We'll mainly be using the `shared_ptr` class, which is designed for pointers that may have more than one owner. The raw pointer is not deleted until all `shared_ptr` owners have gone out of scope or given up ownership.

![Shared pointer](/assets/images/blog-images/path-tracer/the-next-week/shared_ptr.png)

Let's start refactoring from the bottom up - `hittable.h`:
<pre><code class="language-diff-cpp diff-highlight">
	#ifndef HITTABLEH
	#define HITTABLEH

	#include "ray.h"

+	#include &lt;memory>
+	#include &lt;vector>
+	
+	using std::shared_ptr;
+	using std::make_shared;

	class material; // forward declaration

	struct hit_record {
		double t; // parameter of the ray that locates the intersection point
		vec3 p; // intersection point
		vec3 normal;
		bool frontFace;
-		material&#42; material_ptr;
+		shared_ptr&lt;material> material_ptr;

		inline void set_face_normal(const ray& r, const vec3& outward_normal) {
			frontFace = dot(r.direction(), outward_normal) &lt; 0;
			normal = frontFace ? outward_normal : -outward_normal;
		}
	};

	...

</code></pre>


Additionally, we are going to edit `hittableList.h` to not only use shared pointers, but also use [vectors](https://www.cplusplus.com/reference/vector/vector/), which are basically arrays that can change size. Using raw dynamic arrays should generally be avoided, as they come with a heap of responsibility and potential for error, with no real benefits.

`hittableList.h`:
<pre><code class="language-diff-cpp diff-highlight">
#ifndef HITTABLELISTH
#define HITTABLELISTH

#include "hittable.h"

class hittable_list : public hittable {
public:
	hittable_list() {}
-	hittable_list(hittable&#42;&#42; l, int n) { list = l; list_size = n; }
+	hittable_list(shared_ptr&lt;hittable> object) { add(object); }

+	void clear() { objects.clear(); }
+       void add(shared_ptr&lt;hittable> object) { objects.push_back(object); }
	virtual bool hit(const ray& r, double tmin, double tmax, hit_record& rec) const;

-	hittable&#42;&#42; list;
-	int list_size;

+	std::vector&lt;shared_ptr&lt;hittable>> objects;

};

bool hittable_list::hit(const ray& r, double t_min, double t_max, hit_record& rec) const {
	hit_record temp_rec;
	bool hit_anything = false;
	double closest_so_far = t_max;
	for (const auto& object : objects) {
-		for (int i = 0; i &lt; list_size; i++) {
-			if (list[i]->hit(r, t_min, closest_so_far, temp_rec)) {

+		if (object->hit(r, t_min, closest_so_far, temp_rec)) {
+			hit_anything = true;
			closest_so_far = temp_rec.t;
			rec = temp_rec;
		}
	}
	return hit_anything;
}

#endif // !HITTABLELISTH
</code></pre>


`sphere.h`:

<pre><code class="language-diff-cpp diff-highlight">
class sphere : public hittable {
	public:
		sphere() {}
-		sphere(vec3 center, float radius, material &#42;material) : 
+		sphere(vec3 center, float radius, shared_ptr&lt;material> material) : 
			centerStart(center), 
			centerEnd(center), 
			moveStartTime(0),
			moveEndTime(0),
			radius(radius), 
			material_ptr(material){};

		// Moving sphere
-			sphere(vec3 centerStart, vec3 centerEnd, double timeToTravel, float radius, material &#42;material) : 
+		sphere(vec3 centerStart, vec3 centerEnd, double timeToTravel, float radius, shared_ptr&lt;material> material) : 
			centerStart(centerStart),
			centerEnd(centerEnd),
			moveStartTime(moveStartTime), 
			moveEndTime(moveEndTime),
			radius(radius), 
			material_ptr(material){};

		virtual bool hit(const ray &r, double tmin, double tmax, hit_record &rec) const;

		vec3 centerAt(double time) const;

		vec3 centerStart, centerEnd;
		double moveStartTime, moveEndTime;
		double radius;
-		material &#42;material_ptr;
+		shared_ptr&lt;material> material_ptr;
	};

	...

</code></pre>

The changes for `Main.cpp` mostly amount to replacing all uses of keyword `new` with `make_shared`.

`Main.cpp`:

<pre><code class="language-diff-cpp diff-highlight">
...
-	vec3 color(const ray& r, hittable &#42;world, int depth) {
+	vec3 color(const ray& r, hittable_list world, int depth) {
		hit_record rec;

		if (depth &lt;= 0) {
			return vec3(0,0,0);
		}  
-	    if (world->hit(r, 0.001, DBL_MAX, rec)) {
+		if (world.hit(r, 0.001, DBL_MAX, rec)) {
			ray scattered;
			...
	}


-	hittable &#42;random_scene() {
-    int n = 500;
-    hittable &#42;&#42; list = new hittable &#42; n+1];
-    list[0] =  new sphere(vec3(0,-1000,0), 1000, new lambertian(vec3(0.5, 0.5, 0.5))); //"Ground"
-    int i = 1;
-    for (int a = -11; a &lt; 11; a++) {
-        ...
-    }
-	 return new hittable_list(list,i);
-	}
-	


+	hittable_list random_scene() {
+		hittable_list world;
+		
+		auto ground_material = make_shared&lt;lambertian>(vec3(0.5, 0.5, 0.5));
+		auto ground_sphere = make_shared&lt;sphere>(vec3(0,-1000,0), 1000, ground_material);
+
+		world.add(ground_sphere);
+
+		...
+
+		return world;
+	}


int main() {

	int nx = 400; // Number of horizontal pixels
	int ny = 300; // Number of vertical pixels
	int ns = 30; // Number of samples for each pixel for anti-aliasing (see AntiAliasing.png for visualization)
    int maxDepth = 20; // Ray bounce limit
	std::cout &lt;&lt; "P3\n" &lt;&lt; nx &lt;&lt; " " &lt;&lt; ny &lt;&lt; "\n255\n"; // P3 signifies ASCII, 255 signifies max color value

	vec3 lookFrom(0, 2, 24);
	vec3 lookAt(0,1,0);
	double distToFocus = (lookFrom-lookAt).length();
	double aperture = 0.1; // bigger = blurrier

-	hittable &#42;world = random_scene();
+	auto world = random_scene();

	...

}
</code></pre>


### <a id="setting-our-scene"></a>Setting our Scene
Okay - we've got all the maintenence out of the way. Do whatever you please; I simplified the scene to show off our new feature with a black sphere moving from left to right:

<div class="row">
<div class="captioned-image">
<img src="/assets/images/blog-images/path-tracer/the-next-week/blur-speed1-shutter1.png" alt="Moving sphere">
Shutter speed 1, start move at 0, stop move at 1
</div>
<div class="captioned-image" id="wait-then-move-sphere">
<img src="/assets/images/blog-images/path-tracer/the-next-week/blur-start25end75-shutter1.png" alt="Wait then move sphere">
Shutter speed 1, start move at .25, stop move at .75
</div>
</div>

`Main.cpp`:
<pre><code class="language-diff-cpp diff-highlight">

hittable_list random_scene() {
    hittable_list world;
    
    auto ground_material = make_shared&lt;lambertian>(vec3(0.5, 0.5, 0.5));
    auto ground_sphere = make_shared&lt;sphere>(vec3(0,-1000,0), 1000, ground_material);

    world.add(ground_sphere);

-	...

    world.add(make_shared&lt;sphere>(vec3(0, 1, 0), 1.0, make_shared&lt;dielectric>(vec3(0.9,0.9,0.0), 1.5)));
    world.add(make_shared&lt;sphere>(vec3(-4, 1, 0), 1.0, make_shared&lt;lambertian>(vec3(0.4, 0.2, 0.1))));
    world.add(make_shared&lt;sphere>(vec3(4, 1, 0), 1.0, make_shared&lt;metal>(vec3(0.7, 0.6, 0.5), 0.0)));

+    // Moving sphere
+    world.add(make_shared&lt;sphere>(vec3(-4, 3, 0), vec3(4,3,0), 0, 1.0, make_shared&lt;lambertian>(vec3(0.0, 0.0, 0.0))));


    return world;
}

int main() {

	int nx = 1600; // Number of horizontal pixels
	int ny = 900; // Number of vertical pixels
	int ns = 60; // Number of samples for each pixel for anti-aliasing (see AntiAliasing.png for visualization)
    int maxDepth = 20; // Ray bounce limit
	std::cout &lt;&lt; "P3\n" &lt;&lt; nx &lt;&lt; " " &lt;&lt; ny &lt;&lt; "\n255\n"; // P3 signifies ASCII, 255 signifies max color value

	vec3 lookFrom(0, 2, 24);
	vec3 lookAt(0,1,0);
	double distToFocus = (lookFrom-lookAt).length();
	double aperture = 0.1; // bigger = blurrier

	auto world = random_scene();

+	camera cam(lookFrom, lookAt, vec3(0,1,0), 20,double(nx)/double(ny), aperture, distToFocus, 1.0);	

   	auto start = std::chrono::high_resolution_clock::now();


	for (int j = ny - 1; j >= 0; j--) { // Navigate canvas
        std::cerr &lt;&lt; "\rScanlines remaining: " &lt;&lt; j &lt;&lt; ' ' &lt;&lt; std::flush;
		for (int i = 0; i &lt; nx; i++) {
			vec3 col(0, 0, 0);
			for (int s = 0; s &lt; ns; s++) { // Anti-aliasing - get ns samples for each pixel
				double u = (i + random_double(0.0, 0.999)) / double(nx);
				double v = (j + random_double(0.0, 0.999)) / double(ny);
				ray r = cam.get_ray(u, v);
				col += color(r, world, maxDepth);
			}

			col /= double(ns); // Average the color between objects/background
			col = vec3(sqrt(col[0]), sqrt(col[1]), sqrt(col[2]));  // set gamma to 2
			int ir = int(255.99 &#42; col[0]);
			int ig = int(255.99 &#42; col[1]);
			int ib = int(255.99 &#42; col[2]);
			std::cout &lt;&lt; ir &lt;&lt; " " &lt;&lt; ig &lt;&lt; " " &lt;&lt; ib &lt;&lt; "\n";
		}
	}
    
	...

}

</code></pre>

---

<span class="note">
After writing the next section on Bounding Volume Hierarchies, I decided to refactor - I kept getting confused as to what was a class, a method, or a file. There were some inconsistencies in variable names as well. From here on out, variables and functions are camelCase, and classes and files are capitalized. Sorry if this causes any confusion, but it had to be done!
</span>



## <a id="bounding-volume-hierarchies"></a>Bounding Volume Hierarchies

<span class="warning">Whoops! I completed this section, but made a mistake somewhere along the way calcualating the bounding boxes for moving spheres. I only realized in the section following this one when my bouncy balls looked completely wrong under specific conditions: 

![Something ain't right here...](/assets/images/blog-images/path-tracer/the-next-week/bouncy-checkered-ground.png)

I went back to follow Shirley's material more closely to eliminate the issue. So while the ideas in this section are sound, the execution is not! I just *really* don't feel like going through this again. I'd reccommend [skipping to the next section]({{site.url}}/2024/01/03/rt-part-3#implementing-solid-textures) or referring to the [source material](https://raytracing.github.io/books/RayTracingTheNextWeek.html#boundingvolumehierarchies) for BVHs.</span>

<img alt="BVH Illustration" src="/assets/images/blog-images/path-tracer/the-next-week/bounding-volume-hierarchy-wikipedia.svg" style="background: white; padding: 2rem;">

Shirley describes this section as the most difficult part - he justfies tackling it now to avoid future refactoring in addition to significantly reducing runtime. Let's dive in.

If you'd like a succinct primer on the subject, I'd highly reccommend the following video:
<iframe width="560" height="315" src="https://www.youtube.com/embed/EqvtfIqneKA" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>



Calculating ray-object intersections is where our ray tracer spends most of its time - and this time spent increases linearly with the number of objects in a scene. However - as Shirley points out - intersection is a repeated search upon a static model. As such, we should be able to **apply the principles of binary search** (divide and conquer) to our intersection logic.

<span class="captioned-image">
<img src="/assets/images/blog-images/path-tracer/the-next-week/binary-vs-linear.gif" alt="Binary vs linear search">
Average case for binary search ([source](https://blog.penjee.com/binary-vs-linear-search-animated-gifs/))
</span>

In order to use a binary sort in any scenario, the data has to be sorted. Consequently, we have to find a way to "sort" our scene. We'll do this by breaking up the scene into progressively smaller chunks (like a binary tree) using bounding volumes. The most common approaches for sorting ray tracing models are to either bound by space or by scene objects. We'll be bounding by object, as it's simpler.

Here's the "Key Idea" on BVH's from Shirley's book:
> The key idea of a bounding volume over a set of primitives is to find a volume that fully encloses (bounds) all the objects. For example, suppose you computed a bounding sphere of 10 objects. Any ray that misses the bounding sphere definitely misses all ten objects. If the ray hits the bounding sphere, then it might hit one of the ten objects.

It follows that the pseudo-code looks like this:
</code></pre>
if (ray hits bounding object)
    return whether ray hits bounded objects
else
    return false
</code></pre>

One more important aspect of BVH's - any object is in **only one bounding volume**, but **bounding volumes can overlap**.

### <a id="establishing-a-hierarchy"></a>Establishing a Hierarchy

To make intersection checks sub-linear, we need to establish a hierarchy. If we had a set of objects split into two subsets - orange & blue - and we used rectangular bounding volumes in our model, this would be the result:

<img src="/assets/images/blog-images/path-tracer/the-next-week/bounding-hierarchies.png" alt="BVH Illustration" style="
    background: transparent;
">

The orange & blue subsets are simply inside the white rectangle and the binary tree has no order. The pseudo-code for this hierarchy would look like:

<pre><code>
if (hits white)
    hitOrange = hits orange enclosed objects
    hitBlue = hits blue enclosed objects
    if (hitOrange or hitBlue)
        return true and info of closer hit
return false
</code></pre>

### Understanding Axis-Aligned Bounding Boxes (AABBs)

We want our bounding box collisions to be fast and as compact as possible. For this, we'll implement a popular solution - axis-aligned bounding boxes (AABB's). These boxes will be "parallelepipeds" - 3d parallelograms. Another option would be to use spheres, but depending on the shape of the object in question, spheres can result in more false positive collisions than a bounding box (Imagine enclosing a person in a sphere vs. in a box).

![Parallelpiped](/assets/images/blog-images/path-tracer/the-next-week/parallelepiped-wiki.svg)

Since these AABB's are simply containers for our renderable objects, we don't need any additional information about collisions (like normals, materials, or hit points).

To formulate our AABB's, we'll use the slab method. Here's an explanation from [pbr-book.org](https://pbr-book.org/3ed-2018/Shapes/Basic_Shape_Interface):

> One way to think of bounding boxes is as the intersection of three slabs, where a slab is the region of space between two parallel planes. To intersect a ray against a box, we intersect the ray against each of the box’s three slabs in turn.



![Rotating knot with dynamic bounding box](/assets/images/blog-images/path-tracer/the-next-week/rotating-knot.gif) 


Let's start with an AABB example in 2D - a rectangle:

We need see if the ray in question hits the edges of the slab in the x-coordinate space. It will, unless the ray is parallel to the plane.

<span class="captioned-image">
    ![Slab Intersection](/assets/images/blog-images/path-tracer/the-next-week/ray-slab-intersect.svg)
    Slab Intersection (with normal $(1,0,0)$)
</span>

We now check for ray-slab intersections in the y-coordinate space in the same manner. If there's any overlap in $x$ and $y$'s $t$ intervals, that's a collision:

<span class="captioned-image">
    ![AABB Intersection](/assets/images/blog-images/path-tracer/the-next-week/ray-aabb-intersect.svg)
    2D AABB Collision 
    </span>
</span>

In 3D, the edges in question are planes instead of lines. To find where the ray intersects the plane, we can use the function

$$\mathbf{P}(t) = \mathbf{A} + t \mathbf{b}$$ 

$P$ is a point on the ray.
$A$ is the ray origin.
$b$ is the direction of the ray.
The ray parameter $t$ is a real number (positive or negative) that moves $P(t)$ along the ray.

In terms of $x$, the ray hits the plane $x = x_0$ at $t$ that satisfies the equation

$$x_0 = A_x + t_0 b_x$$

Therefore, $t_0$ and $t_1$ can be calculated as follows, respectively:

$$t_0 = \frac{x_0 - A_x}{b_x}$$

$$t_1 = \frac{x_1 - A_x}{b_x}$$

### Implementing AABB Ray Intersections

The simple pseudocode for collisions using the method described in the previous section is as follows:

<pre><code>
compute (tx0, tx1)
compute (ty0, ty1)
compute (tz0, tz1)
return overlap?( (tx0, tx1), (ty0, ty1), (tz0, tz1))
</code></pre> 

There are a couple complications to be aware of:
- The ray could be travelling in the negative direction after having bounced off an object or simply based on the camera's coordinates
- The division of $x_n - A_n$ by $b_n$ could cause infinites
- A ray originating from a slab boundary could result in $NaN$
- SIMD Vectorization issues (Minor and beyond the scope of this post)

To get started addressing these issues and more, we should look to our interval computation:


$$t_0 = \frac{x_0 - A_x}{b_x}$$

$$t_1 = \frac{x_1 - A_x}{b_x}$$

One thing to always be wary of is divison by zero. Funnily enough - valid rays that have a $b$ (direction) of 0 (in any coordinate space - x, y, or z) will cause division by zero. Peter mentions that "Also, the zero will have a ± sign under IEEE floating point" - so maybe we won't *technically* get a divide by zero - I'm a little unsure of why he mentions this. You can read up on signed zero on [Wikipedia](https://en.wikipedia.org/wiki/Signed_zero) or [StackOverflow](https://stackoverflow.com/questions/42926763/the-behaviour-of-floating-point-division-by-zero). Anyway, when $b = 0$, $t_0$ and $t_1$ will both be either +∞ or -∞ if not between coordinate $x_0$ and $x_1$, which means that we can use min and max to get the correct values.




$$
    t_{x0} = \min(
     \frac{x_0 - A_x}{b_x},
     \frac{x_1 - A_x}{b_x})
$$



$$
    t_{x1} = \max(
    \frac{x_0 - A_x}{b_x},
    \frac{x_1 - A_x}{b_x})
$$


> The remaining troublesome case if we do that is if $b_x=0$ and either $x_0−A_x=0$ or $x_1−A_x=0$ so we get NaN. In that case we can probably accept either hit or no hit answer, but we’ll revisit that later.

Now we need to think about how we're going to implement the overlap function - we're going to assume that the edges are in order - that is, $x_0$ / $y_0$ / $z_0$ is always less than $x_1$ / $y_1$ / $z_1$  Let's think about it in 2D again:


![AABB Intersection](/assets/images/blog-images/path-tracer/the-next-week/ray-aabb-intersect.svg)

We're going to simply check if either $y_0$ or $y_1$ are contained within ($x_0$, $x_1$).

We can extend this concept to 3D:

<pre><code>
bool overlap(x0, x1, y0, y1, z0, z1)
    z0 = max(x0, y0)
    z1 = min(x1, y1)
    return (z0 &lt; z1)
</code></pre> 

> If there are any NaNs running around there, the compare will return false so we need to be sure our bounding boxes have a little padding if we care about grazing cases (and we probably should because in a ray tracer all cases come up eventually).

Translated to C++:

<pre><code class="language-cpp">
#ifndef BOUNDINGBOXH
#define BOUNDINGBOXH

#include "RtWeekend.h"

class BoundingBox {
    public:
        BoundingBox() {}
        BoundingBox(const Vec3& a, const Vec3& b) { minimum = a; maximum = b;}

        vec3 min() const {return minimum; }
        vec3 max() const {return maximum; }

        bool hit(const Ray& r, double tMin, double tMax) const {
            for (int a = 0; a &lt; 3; a++) {
                auto t0 = fmin((minimum[a] - r.origin()[a]) / r.direction()[a],
                               (maximum[a] - r.origin()[a]) / r.direction()[a]);
                auto t1 = fmax((minimum[a] - r.origin()[a]) / r.direction()[a],
                               (maximum[a] - r.origin()[a]) / r.direction()[a]);
                tMin = fmax(t0, tMin);
                tMax = fmin(t1, tMax);
                if (tMax &lt;= tMin)
                    return false;
            }
            return true;
        }

        vec3 minimum;
        vec3 maximum;
};

#endif
</code></pre>

### Creating Bounding Boxes for our Hittables
We'll need a function to compute the bounding boxes of hittables. We can create a hierarchy of bounding boxes enclosing all primitives, and the individual primitives (like single spheres) will be the leaves at the bottom of the hierarchy.

Our bounding box function will return a bool because some primitives (like planes) don't have bounding boxes.

Moving objects will have a bounding box that will enclose the primitive from timeStart to timeEnd.

First, we'll create a virtual function in `Hittable.h`:

<pre><code class="language-diff-cpp diff-highlight">
+ #include "BoundingBox.h"

...

class Hittable {
public: 
	virtual bool hit(const Ray& r, double tMin, double tMax, HitRecord& rec) const = 0;
+	virtual bool generateBoundingBox(double time0, double time1, BoundingBox& outputBox) const = 0;

};
</code></pre>

and override it in `Sphere.h`:

<pre><code class="language-cpp">bool Sphere::generateBoundingBox(double timeStart, double timeEnd, BoundingBox& outputBox) const {
	
	
	BoundingBox box0 = BoundingBox(
			centerAt(timeStart) - vec3(radius, radius, radius),
			centerAt(timeStart) + vec3(radius, radius, radius));

	// Sphere is not moving
	if (timeStart-timeEnd &lt; epsilon ) {
		outputBox = box0
		return true;
	}

	else {
		BoundingBox box1 = BoundingBox(
			centerAt(timeEnd) - vec3(radius, radius, radius),
			centerAt(timeEnd) + vec3(radius, radius, radius));
		
		outputBox = generateSurroundingBox(box0, box1)
                return true;
	}

	
}
</code></pre>

We now need to implement the non-member `generateSurroundingBox` function in `BoundingBox.h`:


<pre><code class="language-cpp">BoundingBox generateSurroundingBox(BoundingBox box0, BoundingBox box1) const {
            
            double x,y,z;

            x = fmin(box0.min().x(), box1.min().x());
            y = fmin(box0.min().y(), box1.min().y());
            z = fmin(box0.min().z(), box1.min().z());

            vec3 min {x, y, z};



            x = fmax(box0.max().x(), box1.max().x());
            y = fmax(box0.max().y(), box1.max().y());
            z = fmax(box0.max().z(), box1.max().z());

            vec3 max {x, y, z};

            return BoundingBox(min, max);
        }
</code></pre>


### Creating Bounding Boxes for Lists of Hittables 


Similarly, we'll have to add to our `HittableList` class:

<pre><code class="language-cpp">
#ifndef HITTABLELISTH
#define HITTABLELISTH

#include "Hittable.h"

class HittableList : public Hittable {
public:
	HittableList() {}
	HittableList(shared_ptr&lt;Hittable> object) { add(object); }

	void clear() { objects.clear(); }
        void add(shared_ptr&lt;Hittable> object) { objects.push_back(object); }
	virtual bool hit(const Ray& r, double tMin, double tMax, HitRecord& rec) const override;
+	virtual bool generateboundingBox(double timeStart, double timeEnd, BoundingBox& outputBox) const override;

	std::vector&lt;shared_ptr&lt;Hittable>> objects;

};

bool HittableList::hit(const Ray& r, double tMin, double tMax, HitRecord& rec) const {
	HitRecord tempHitRec;
	bool hitStatus = false;
	double closestSoFar = tMax;
	for (const auto& object : objects) {

		if (object->hit(r, tMin, closestSoFar, tempHitRec)) {
			hitStatus = true;
			closestSoFar = tempHitRec.t;
			rec = tempHitRec;
		}
	}
	return hitStatus;
	
}

+   bool HittableList::generateBoundingBox(double timeStart, double timeEnd, BoundingBox &outputBox) const {
+   	
+   	if (objects.empty()) {
+   		return false;
+   	}
+   
+       BoundingBox tempBox;
+       bool isFirstBox = true;
+   
+       for (const auto& object : objects) {
+           if (!object-&gt;generateBoundingBox(timeStart, timeEnd, tempBox)) return false;
+           outputBox = isFirstBox ? tempBox :  generateSurroundingBox(outputBox, tempBox);
+           isFirstBox = false;
+       }
+   
+       return true;
+   	
+   }

#endif // !HITTABLELISTH
</code></pre> 

### Defining our Hittable BVH Class
Our BVHs need to be `hittable`s.

Take note of the fact that the child nodes point to generic `Hittable`s - they can other BVHs, spheres, or any kind of hittable.

<pre><code class="language-cpp">#ifndef BVHH
#define BVHH

#include "RtWeekend.h"

#include "Hittable.h"
#include "HittableList.h"


class BvhNode : public Hittable {
    public:
    
        BvhNode();

        BvhNode(const HittableList& list, double timeStart, double timeEnd)
            : BvhNode(list.objects, 0, list.objects.size(), timeStart, timeEnd)
        {}

        BvhNode(
            const std::vector&lt;shared_ptr&lt;hittable>>& srcObjects,
            size_t start, size_t end, double timeStart, double timeEnd);

        virtual bool hit(
            const Ray& r, double tMin, double tMax, HitRecord& rec) const override;

        virtual bool generateBoundingBox(double timeStart, double timeEnd, BoundingBox& outputBox) const override;

    public:
        shared_ptr&lt;hittable> left;
        shared_ptr&lt;hittable> right;
        BoundingBox box;
};

bool BvhNode::hit(const Ray& r, double tMin, double tMax, HitRecord& rec) const {
    if (!box.hit(r, tMin, tMax))
        return false;

    bool hitLeft = left->hit(r, tMin, tMax, rec);
    bool hitRight = right->hit(r, tMin, hitLeft ? rec.t : tMax, rec);

    return hitLeft || hitRight;
}

bool BvhNode::generateBoundingBox(double timeStart, double timeEnd, BoundingBox& outputBox) const {
    outputBox = box;
    return true;
}

#endif
</code></pre>

### Splitting BVH Volumes

> The most complicated part of any efficiency structure, including the BVH, is building it.

These BVHs can be hard to create a mental image for - here's a video to help:

<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/rM-BVsdi8c4" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

We'll be building the BVH in the constructor. The BVH doesn't have to be perfect - as long as the list of `hittables` in a node gets divided into two sublists, the BVH `hit` function will work. Shirley notes that the best/fastest scenario is if the children `hittable`s have smaller bounding boxes than their parent.

We'll follow Shirley's lead and adopt a simplistic middle-ground method:

1. Randomly choose an axis
2. Sort the primitives
3. Store the primitives as evenly as possible across subtrees

When the incoming `vector` object has a size of two, that's when we can stop recursing and put each of the two hittables in their respective subtrees.

First, let's add a utility function to `RtWeekend.h` to return a random int in a given range:

<pre><code class="language-cpp">inline int randomInt(int min, int max) {
    // Returns a random integer in [min,max].
    return static_cast&lt;int>(randomDouble(min, max+1));
}
</code></pre>

Now we can start forming our BVH class:


<pre><code class="language-cpp">

#ifndef BVHH
#define BVHH

#include &lt;algorithm>
#include "RtWeekend.h"
#include "Hittable.h"
#include "HittableList.h"

class BvhNode : public Hittable {
    public:

        BvhNode();
        BvhNode(const HittableList& list, double timeStart, double timeEnd)
            : BvhNode(list.objects, 0, list.objects.size(), timeStart, timeEnd)
        {}

        BvhNode(
                const std::vector&lt;shared_ptr&lt;Hittable>>& srcObjects,
                size_t start, size_t end, double timeStart, double timeEnd);

        virtual bool hit(
                const Ray& r, double tMin, double tMax, HitRecord& rec) const override;

        virtual bool generateBoundingBox(double timeStart, double timeEnd, BoundingBox& outputBox) const override;

    public:
        shared_ptr&lt;hittable> left;
        shared_ptr&lt;hittable> right;
        BoundingBox box;
};
</code></pre>


Let's define the constructors and member functions:
<pre><code class="language-cpp">


BvhNode::BvhNode(
        std::vector&lt;shared_ptr&lt;Hittable>>& srcObjects,
        size_t start, size_t end, double timeStart, double timeEnd
        ) {
    auto objects = srcObjects; // Create a modifiable array of the source scene objects

    // Determine random axis
    int axis = randomInt(0,2);

    // *The comparators will be implemented later on*
    auto comparator = (axis == 0) ? compareX
        : (axis == 1) ? compareY 
        : compareZ;

    size_t objectSpan = end - start;

    // Sort the primitives
    if (objectSpan == 1) {
        left = right = objects[start];
    } else if (objectSpan == 2) {
        if (comparator(objects[start], objects[start+1])) {
            left = objects[start];
            right = objects[start+1];
        } else {
            left = objects[start+1];
            right = objects[start];
        }
    } else {
        std::sort(objects.begin() + start, objects.begin() + end, comparator);

        auto mid = start + objectSpan/2;
        left = make_shared&lt;BvhNode>(objects, start, mid, timeStart, timeEnd);
        right = make_shared&lt;BvhNode>(objects, mid, end, timeStart, timeEnd);
    }

    aabb boxLeft, boxRight;

    if (  !left->generateBoundingBox (timeStart, timeEnd, boxLeft)
            || !right->generateBoundingBox(timeStart, timeEnd, boxRight)
       )
        std::cerr &lt;&lt; "No bounding box in BvhNode constructor.\n";

    box = generateSurroundingBox(boxLeft, boxRight);
}

bool BvhNode::hit(const Ray& r, double tMin, double tMax, HitRecord& rec) const {
    if (!box.hit(r, tMin, tMax))
        return false;

    bool hitLeft = left->hit(r, tMin, tMax, rec);
    bool hitRight = right->hit(r, tMin, hitLeft ? rec.t : tMax, rec);

    return hitLeft || hitRight;
}

bool BvhNode::generateBoundingBox(double timeStart, double timeEnd, BoundingBox& outputBox) const {
    outputBox = box;
    return true;
}

#endif

</code></pre> 


### Adding our Box Comparison Functions

First of all, let's define some axis `enum`s in `RtWeekend.h`:
<pre><code class="language-cpp">
...

// Constants
const double infinity = std::numeric_limits&lt;double>::infinity();
const double pi = 3.1415926535897932385;
const double epsilon = 0.00001;

+   // Enums
+   enum Axis { x, y, z };

// Utility Functions
inline double degreesToRadians(double degrees) {
    return degrees * pi / 180;
}
...
</code></pre> 

Now we can add a generic non-member comparator to `BoundingBox` (right above the implementation of our `BvhNode` constructor):

<pre><code class="language-cpp">
inline bool box_compare(const shared_ptr&lt;hittable> a, const shared_ptr&lt;hittable> b, int axis) {
    aabb box_a;
    aabb box_b;

    if (!a->bounding_box(0,0, box_a) || !b->bounding_box(0,0, box_b))
        std::cerr &lt;&lt; "No bounding box in bvh_node constructor.\n";

    return box_a.min().e[axis] &lt; box_b.min().e[axis];
}
</code></pre>

and the calls to the comparator (right above the implementation of our `BvhNode` constructor):

<pre><code class="language-cpp">
bool compareX (const shared_ptr&lt;Hittable> a, const shared_ptr&lt;Hittable> b) {
    return compare(a, b, Axis::x);
}

bool compareY (const shared_ptr&lt;Hittable> a, const shared_ptr&lt;Hittable> b) {
    return compare(a, b, Axis::y);
}

bool compareZ (const shared_ptr&lt;Hittable> a, const shared_ptr&lt;Hittable> b) {
    return compare(a, b, Axis::z);
}
</code></pre> 

![Our control image for testing BVH optimization](/assets/images/blog-images/path-tracer/the-next-week/with-bvh.png)

The difference in rendering time for the above image is clear:

<pre><code class="language-terminal">
evan@evan-ThinkPad-E495:~/Projects/PathTracer/src$ ./a.out > without-bvh.ppm
Scanlines remaining: 0
Done in:
	1 hours
	9 minutes
	16 seconds.
</code></pre> 

<pre><code class="language-terminal">evan@evan-ThinkPad-E495:~/Projects/PathTracer/src$ ./a.out > with-bvh.ppm 
Scanlines remaining: 0   
Finished in:
	0 hours
	13 minutes
	45 seconds.
</code></pre>


### Implementing Solid Textures
> A texture in graphics usually means a function that makes the colors on a surface procedural.

> The most common type of texture mapping maps an image onto the surface of an object, defining the color at each point on the object’s surface. In practice, we implement the process in reverse: given some point on the object, we’ll look up the color defined by the texture map. 

The aforementioned function could be synthesis, an image lookup, or somewhere in between. We'll be keeping things simple to start - our first texture will be a solid color.



#### Constant Color Textures
We'll start with an [abstract class](https://www.ibm.com/docs/en/zos/2.4.0?topic=only-abstract-classes-c) `Texture`:

```cpp
#ifndef TEXTURE_H
#define TEXTURE_H

#include "RtWeekend.h"

class Texture {
    public:
        virtual Vec3 value(double u, double v, const Vec3& p) const = 0;
};
```

We'll extend `Texture` to implement `SolidColor`:
```cpp
class SolidColor : public Texture {
    public:
        SolidColor(Vec3 c) : colorValue(c) {}

        SolidColor(double red, double green, double blue)
          : SolidColor(Vec3(red,green,blue)) {}

        // Return the texture color of the given coordinates		
        virtual Vec3 value(double u, double v, const Vec3& p) const override {
            return colorValue;
        }

    private:
        Vec3 colorValue;
};

#endif
```

You may be wondering about the parameters $u$ and $v$ - these are the conventional names for two-dimensional texture coordinates. For a constant textures - like a solid color - we will not be using them, but they will come into play eventually. As such, we have to update our HitRecord class with members $u$ and $v$:

`Hittable.h`
```cpp
...
struct HitRecord {
	double t; // parameter of the ray that locates the intersection point
	
	// Texture coordinates
	double u;
	double v;

	Vec3 p; // intersection point
	Vec3 normal;
	bool frontFace;
	shared_ptr<Material> materialPtr;

	inline void setFaceNormal(const Ray& r, const Vec3& outwardNormal) {
        frontFace = dot(r.direction(), outwardNormal) < 0;
        normal = frontFace ? outwardNormal : -outwardNormal;
    }
};
...
```

#### Solid Checkered Textures
Solid (AKA spatial) textures depend only upon the postiton of each point in 3d space. I like to think of these textures as suspended swimming pools that objects swim through (instead assigning a color to a given object). However, the relationship between the object and the texture is usually fixed.

The checkerboard pattern is a perfect way to explore spatial textures (and it's a ray-tracing staple!). Let's create a `CheckerTexture` class. Because spatial texture functions are described by a position in space, the `value()` function doesn't make use of the $u$ members $v$. Just the point parameter $p$.

First, we compute the floor value of each component of the input point $(x,y,z)$. The reason that we take the floor instead of truncating values is to account for both positive and negative components. For example, the floor of 2.7 is 2.0, but the floor of -2.7 is -3.0. From here, we take the sum of the floors of $(x,y,z)$ modulo 2 to get either 0 or 1 to determine our checker square color.

Lastly, we'll add a scale factor to control the square size.

`Texture.h`
```cpp
...

class CheckerTexture : public Texture {
    public:
        CheckerTexture(double scale, shared_ptr<Texture> even, shared_ptr<Texture> odd) 
            :   invertedScale(1.0 / scale), 
                even(even), 
                odd(odd) {}

        CheckerTexture(double scale, Vec3 colorOne, Vec3 colorTwo) 
            :   invertedScale(1.0 / scale), 
                even(make_shared<SolidColor>(colorOne)), 
                odd(make_shared<SolidColor>(colorTwo)) {}

        Vec3 value(double u, double v, const Vec3& p) const override {
            auto xFloor = static_cast<int>(std::floor(invertedScale * p.x()));
            auto yFloor = static_cast<int>(std::floor(invertedScale * p.y()));
            auto zFloor = static_cast<int>(std::floor(invertedScale * p.z()));

            bool isEven = (xFloor + yFloor + zFloor) % 2 ? true : false;

            return isEven ? even->value(u, v, p) : odd->value(u, v, p);
        }

    private:
        double invertedScale;
        shared_ptr<Texture> even;
        shared_ptr<Texture> odd;

};

...

```

With some minor changes to our `generateRandomScene()` function, we can turn our "ground" sphere into a checkered behemoth:



NOTE:
it looks like the update to `generateRandomScene()` actually requires some changes to `Material.h` that Shirley hasn't gotten to yet - we have to support textured materials by replacing `const Vec3& a` with a texture pointer:
`Material.h`:
```cpp
#include "Texture.h"

...

class Lambertian : public Material {
    public:
-       Lambertian(const Vec3& a) : albedo(a){};
+       Lambertian(const Vec3& a) : albedo(make_shared<SolidColor>(a)) {};
+       Lambertian(shared_ptr<Texture> a) : albedo(a) {}

        virtual bool scatter(const Ray& rayIn, 
                            const HitRecord& rec, 
                            Vec3& attenuation, 
                            Ray& scattered) const {
            Vec3 scatterDirection = rec.p + rec.normal + randomUnitVector();
            scattered = Ray(rec.p, scatterDirection - rec.p, rayIn.moment());
-           attenuation = albedo;
+           attenuation = albedo->value(rec.u, rec.v, rec.p);
            return true;
        }
-   Vec3 albedo; // reflectivity
+   shared_ptr<Texture> albedo; // reflectivity

...


```





`Main.cpp`:
```cpp

HittableList generateRandomScene(bool useBvh = true) {
    HittableList world;

    // auto groundMaterial = make_shared<Lambertian>(Vec3(0.5, 0.5, 0.5));
    // world.add(make_shared<Sphere>(Vec3(0,-1000,0), 1000, groundMaterial));

    auto checkerPattern = make_shared<CheckerTexture>(0.32, Vec3(.2, .3, .1), Vec3(.9, .9, .9));
    world.add(make_shared<Sphere>(Vec3(0,-1000,0), 1000, make_shared<Lambertian>(checkerPattern)));


    for (int a = -11; a < 11; a++) {
        for (int b = -11; b < 11; b++) {
            ...
    }

    ...

}

```

While we're here in `Main.cpp`, let's make things cleaner by moving the rendering logic to `Camera.h` and compartmentalizing scenes. There are quite a few changes, so here are the files in their entirety (check the [commit history](https://github.com/eldun/PathTracer/commits/the-next-week) if you want more details):

`Main.cpp`:
```cpp

#include <chrono> // Record elapsed render time
#include <iostream>
#include <iomanip> // Time formatting
#include <float.h>

#include "RtWeekend.h"

#include "BvhNode.h"
#include "Sphere.h"
#include "HittableList.h"
#include "Camera.h"
#include "Material.h"
#include "Texture.h"

/****************************************************************************************
The code for this path tracer is based on "Ray Tracing in One Weekend" by Peter Shirley.
				https://github.com/RayTracing/raytracing.github.io

Additional/better graphics to illustrate Ray tracing from the "1000 Forms of Bunnies" blog.
				http://viclw17.github.io/tag/#/Ray%20Tracing%20in%20One%20Weekend
*****************************************************************************************/


void generateMovingSphereComparisonScene() {
    HittableList world;

    auto groundMaterial = make_shared<Lambertian>(Vec3(0.5, 0.5, 0.5));
    auto groundSphere = make_shared<Sphere>(Vec3(0,-1000,0), 1000, groundMaterial);

    world.add(groundSphere);

    world.add(make_shared<Sphere>(Vec3(0, 1, 0), 1.0, make_shared<Dielectric>(Vec3(0.9,0.9,0.0), 1.5)));
    world.add(make_shared<Sphere>(Vec3(-4, 1, 0), 1.0, make_shared<Lambertian>(Vec3(0.4, 0.2, 0.1))));
    world.add(make_shared<Sphere>(Vec3(4, 1, 0), 1.0, make_shared<Metal>(Vec3(0.7, 0.6, 0.5), 0.0)));

    // Moving Sphere
    world.add(make_shared<Sphere>(Vec3(-4, 3, 0), Vec3(4,3,0),.25, .75, 1.0, make_shared<Lambertian>(Vec3(0.0, 0.0, 0.0))));

    // BVH
    world = HittableList(make_shared<BvhNode>(world, 0.0, 1.0));

    Camera cam;
    cam.render(world);
}

void generateRandomScene(bool useBvh = true) {
    HittableList world;

    // auto groundMaterial = make_shared<Lambertian>(Vec3(0.5, 0.5, 0.5));
    // world.add(make_shared<Sphere>(Vec3(0,-1000,0), 1000, groundMaterial));

    auto checkerPattern = make_shared<CheckerTexture>(0.32, Vec3(.2, .3, .1), Vec3(.9, .9, .9));
    world.add(make_shared<Sphere>(Vec3(0,-1000,0), 1000, make_shared<Lambertian>(checkerPattern)));


    for (int a = -11; a < 11; a++) {
        for (int b = -11; b < 11; b++) {
            auto materialChance = randomDouble();
            Vec3 center(a + 0.9*randomDouble(), 0.2, b + 0.9*randomDouble());

            if ((center - Vec3(4, 0.2, 0)).length() > 0.9) {
                shared_ptr<Material> sphereMaterial;

                if (materialChance < 0.8) {
                    // diffuse
                    auto albedo = Vec3::random() * Vec3::random();
                    sphereMaterial= make_shared<Lambertian>(albedo);
                    world.add(make_shared<Sphere>(center, 0.2, sphereMaterial));
                } else if (materialChance < 0.95) {
                    // metal
                    auto albedo = Vec3::random(0.5, 1);
                    auto fuzz = randomDouble(0, 0.5);
                    sphereMaterial = make_shared<Metal>(albedo, fuzz);
                    world.add(make_shared<Sphere>(center, 0.2, sphereMaterial));
                } else {
                    // glass
                    sphereMaterial = make_shared<Dielectric>(Vec3(0.9, 0.9, 0.9), 1.5);
                    world.add(make_shared<Sphere>(center, 0.2, sphereMaterial));
                }
            }
        }
    }

    auto material1 = make_shared<Dielectric>(Vec3(0.9, 0.9, 0.9), 1.5);
    world.add(make_shared<Sphere>(Vec3(0, 1, 0), 1.0, material1));

    auto material2 = make_shared<Lambertian>(Vec3(0.4, 0.2, 0.1));
    world.add(make_shared<Sphere>(Vec3(-4, 1, 0), 1.0, material2));

    auto material3 = make_shared<Metal>(Vec3(0.7, 0.6, 0.5), 0.0);
    world.add(make_shared<Sphere>(Vec3(4, 1, 0), 1.0, material3));

    if (useBvh)
        world = HittableList(make_shared<BvhNode>(world, 0.0, 1.0));

    Camera cam;
    cam.render(world);

}

int main() {

    switch (0) {
    case 0:
        generateRandomScene();
        break;

    case 1:
        generateMovingSphereComparisonScene();
        break;

    default:
        generateRandomScene();
        break;
    }

    return 0;
   
}

```

```cpp

#ifndef CAMERA_H
#define CAMERA_H

#include "RtWeekend.h"

#include "Ray.h"
#include "Material.h"

class Camera {
public:

    int imageWidth = 320; // Number of horizontal pixels
	int samplesPerPixel = 60; // Number of samples for each pixel for anti-aliasing (see AntiAliasing.png for visualization)
    int maxDepth = 20; // Ray bounce limit

	Vec3 lookFrom = Vec3(13,2,3);
	Vec3 lookAt = Vec3(0, 0, 0);
    Vec3 upDirection = Vec3(0,1,0);
    double vFov = 20;
    double aspectRatio = 16.0 / 9.0;
	double focusDistance = (lookFrom-lookAt).length();
    double shutterOpenDuration = 1.0;
	double aperture = 0.1; // bigger = blurrier

    void render(Hittable& world) {
        initialize();


        // .ppm header 
        std::cout << "P3\n" << imageWidth << " " << imageHeight << "\n255\n"; // - P3 signifies ASCII, 255 signifies max color value


        auto start = std::chrono::high_resolution_clock::now();


        for (int j = imageHeight - 1; j >= 0; j--) { // Navigate canvas
            std::cerr << "\rScanlines remaining: " << j << ' ' << std::flush;
            for (int i = 0; i < imageWidth; i++) {
                Vec3 col(0, 0, 0);
                for (int s = 0; s < samplesPerPixel; s++) { // Anti-aliasing - get ns samples for each pixel
                    double u = (i + randomDouble(0.0, 0.999)) / double(imageWidth);
                    double v = (j + randomDouble(0.0, 0.999)) / double(imageHeight);
                    Ray r = getRay(u, v);
                    col += color(r, world, maxDepth);
                }

                col /= double(samplesPerPixel); // Average the color between objects/background
                col = Vec3(sqrt(col[0]), sqrt(col[1]), sqrt(col[2]));  // set gamma to 2
                int ir = int(255.99 * col[0]);
                int ig = int(255.99 * col[1]);
                int ib = int(255.99 * col[2]);
                std::cout << ir << " " << ig << " " << ib << "\n";
            }
        }
        auto stop = std::chrono::high_resolution_clock::now();

        auto hours = std::chrono::duration_cast<std::chrono::hours>(stop - start);
        auto minutes = std::chrono::duration_cast<std::chrono::minutes>(stop - start) - hours;
        auto seconds = std::chrono::duration_cast<std::chrono::seconds>(stop - start) - hours - minutes;

        std::cerr << std::fixed << std::setprecision(2) <<
        "\nFinished in:" << std::endl <<
        "\t" << hours.count() << " hours" << std::endl <<
        "\t" << minutes.count() << " minutes" << std::endl <<
        "\t" << seconds.count() << " seconds." << std::endl;
    }

    Ray getRay(double s, double t)
    {
        Vec3 rd = lensRadius * randomUnitDiskCoordinate();
        Vec3 offset = u * rd.x() + v * rd.y();
        return Ray(origin + offset,
                   lowerLeftCorner + s * horizontal + t * vertical - origin - offset,
                   randomDouble(0, shutterOpenDuration));
    }

private:
    Vec3 origin;
    Vec3 lowerLeftCorner;
    Vec3 horizontal;
    Vec3 vertical;
    Vec3 u, v, w;
    double lensRadius;
    double imageHeight;

        // Camera(Vec3 lookFrom, Vec3 lookAt, Vec3 upDirection, double vFov, double aspectRatio,
    //        double aperture, double focusDistance, double shutterOpenDuration)
    void initialize() {
        imageHeight = static_cast<int>(imageWidth / aspectRatio);
        imageHeight = (imageHeight < 1) ? 1 : imageHeight;

        lensRadius = aperture / 2;
        double theta = vFov * pi / 180;
        double halfHeight = tan(theta / 2);
        double halfWidth = aspectRatio * halfHeight;
        origin = lookFrom;
        w = unitVector(lookFrom - lookAt);
        u = unitVector(cross(upDirection, w));
        v = cross(w, u);
        lowerLeftCorner = origin - halfWidth * focusDistance * u - halfHeight * focusDistance * v - focusDistance * w;
        horizontal = 2 * halfWidth * focusDistance * u;
        vertical = 2 * halfHeight * focusDistance * v;
    }

    Vec3 color(const Ray& r, const Hittable& world, int depth) {
        HitRecord rec;

        if (depth <= 0) {
            return Vec3(0,0,0);
        }
        if (world.hit(r, 0.001, DBL_MAX, rec)) {
            Ray scattered;
            Vec3 attenuation;
            if (rec.materialPtr->scatter(r, rec, attenuation, scattered)) {
                return attenuation*color(scattered, world, depth-1);
            }
            else {
                return Vec3(0,0,0);
            }
        }

        // Linear interpolation (sky)
        else {
            Vec3 unitDirection = unitVector(r.direction());
            double t = 0.5*(unitDirection.y() + 1.0);
            return (1.0-t)*Vec3(1.0, 1.0, 1.0) + t*Vec3(0.5, 0.7, 1.0);
        }
    }
};

#endif // !CAMERA_H

```

The result:

![Our first checkered texture render](/assets/images/blog-images/path-tracer/the-next-week/checkered-ground.png)

With moving spheres:

![Checkered texture render with moving spheres](/assets/images/blog-images/path-tracer/the-next-week/bouncy-checkered-ground.png)

Looks wrong, right? I thought I had messed up somewhere. Turns out, I did. I made a mistake somewhere in calculating the bounding box.o for moving spheres. The expected image:

![Peter Shirley's spatial texture preview image](/assets/images/blog-images/path-tracer/the-next-week/spatial-texture-preview.png)

Anyway, I went back and fixed it.

Let's add another scene to better illustrate the issue we'll address next:

`Main.cpp`:
```cpp
void generateTwoSpheres() {
    HittableList world;

    auto checker = make_shared<CheckerTexture>(0.8, Vec3(.2, .3, .1), Vec3(.9, .9, .9));

    world.add(make_shared<Sphere>(Vec3(0,-10, 0), 10, make_shared<Lambertian>(checker)));
    world.add(make_shared<Sphere>(Vec3(0, 10, 0), 10, make_shared<Lambertian>(checker)));

    Camera cam;

    cam.vFov        = 20;
    cam.lookFrom    = Vec3(13,2,3);
    cam.lookAt      = Vec3(0,0,0);
    cam.upDirection = Vec3(0,1,0);

    cam.render(world);
}
```

![Two checkered spheres to illustrate a mapping issue](/assets/images/blog-images/path-tracer/the-next-week/two-spheres.png)

> Since checker_texture is a spatial texture, we're really looking at the surface of the sphere cutting through the three-dimensional checker space. There are many situations where this is perfect, or at least sufficient. In many other situations, we really want to get a consistent effect on the surface of our objects.

---

#### Texture Coordinates for Spheres
This is the part where we actually implement and use $u$ and $v$.

From [Wikipedia](https://en.wikipedia.org/wiki/UV_mapping):
> UV mapping is the 3D modeling process of projecting a 3D model's surface to a 2D image for texture mapping. The letters "U" and "V" denote the axes of the 2D texture because "X", "Y", and "Z" are already used to denote the axes of the 3D object in model space, while "W" (in addition to XYZ) is used in calculating quaternion rotations, a common operation in computer graphics.

![UV Mapping](/assets/images/blog-images/path-tracer/the-next-week/uv-mapping.png) 

One more tidbit I'd like to include from Shirley:
> This mapping is completely arbitrary, but generally you'd like to cover the entire surface, and be able to scale, orient and stretch the 2D image in a way that makes some sense.

For spheres, texture coordinates are usually based on latitude and longitude - theta ($θ$) and phi ($ϕ$), respectively.

![The spherical coordinate system](/assets/images/blog-images/path-tracer/the-next-week/spherical-coordinate-system.png)

In an effort to stick as closely as possible to Shirley's guide, we'll be diverging slightly from the illustration above by defining $θ$ as the angle northward from the south pole (i.e. up from $-y$) and $ϕ$ as the angle around the y-axis ($-x$ -> $+z$ -> $+x$ -> $-z$ -> $-x$).

Okay. So, we want to map spherical coordinates ($θ$,$ϕ$) to ($u$,$v$) in \[0,1] where ($u$=0, $v$=0) maps to the bottom-left corner of the texture. 

To normalize $u$ and $v$ to each fall between 0 and 1, we'd do the following:

$$
u = \frac{\phi}{2\pi}\\
v = \frac{\theta}{\pi} #
$$

To get $\theta$ and $\phi$ for any given point on the unit sphere, we'll begin with the equation for cartesian coordinates. [This page](https://mathinsight.org/spherical_coordinates) does an excellent job of illustrating the conversion process between Cartesian and spherical coordinates - although the definitions of our variables are slightly different.

$$
\begin{align*}
      y &= -\cos(\theta)            \\
      x &= -\cos(\phi) \sin(\theta) \\
      z &= \quad\sin(\phi) \sin(\theta)
     \end{align*}
$$

To get the $ (\theta, \phi) $ coordinates, the equations above have to be [inverted](https://www.mathsisfun.com/algebra/trig-inverse-sin-cos-tan.html) using $ \arcsin $ and $ \arctan $. These functions (like [atan2](https://en.wikipedia.org/wiki/Atan2)) can be found in `<cmath>`.

> atan2() returns values in the range −π to π, but they go from 0 to π, then flip to −π and proceed back to zero. While this is mathematically correct, we want u to range from 0 to 1, not from 0 to 1/2 and then from −1/2 to 0. Fortunately,
>
>atan2(a,b)=atan2(−a,−b)+π,
>
>and the second formulation yields values from 0
>continuously to 2π. Thus, we can compute ϕ
>
>as
>
>ϕ=atan2(−z,x)+π

And for $\theta$:

$$
\theta = \arccos(-y)
$$


Let's translate all this to code - `Sphere::getUvCoordinates()` - which will take points on the unit sphere centered at the origin, and compute $u$ and $v$:

```
void Sphere::getUvCoordinates(const Vec3& p, double& u, double& v){
	// p: a given point on the sphere of radius one, centered at the origin.
	// u: returned value [0,1] of angle around the Y axis from X=-1.	
	// v: returned value [0,1] of angle from Y=-1 to Y=+1.	
	//     <1 0 0> yields <0.50 0.50>       <-1  0  0> yields <0.00 0.50>	
	//     <0 1 0> yields <0.50 1.00>       < 0 -1  0> yields <0.50 0.00>	
	//     <0 0 1> yields <0.25 0.50>       < 0  0 -1> yields <0.75 0.50>	

	auto theta = acos(-p.y());
	auto phi = atan2(-p.z(), p.x()) + pi;

	u = phi / (2*pi);
	v = theta / pi;
}
```

From here, we need to update our `hit_record` with the UV coordinates:

```
class Sphere : public Hittable {
  public:
    ...
    bool hit(const ray& r, interval ray_t, hit_record& rec) const override {
        ...

		rec.t = root;
        rec.p = r.pointAtParameter(rec.t);
        Vec3 outward_normal = (rec.p - center) / radius;
        rec.setFaceNormal(r, outward_normal);
        getUvCoordinates(outward_normal, rec.u, rec.v);
		rec.materialPtr = materialPtr;

        return true;	
    }
    ...
};
```

If you've been following my blog, your Lambertian class in `Material.h` should already look like this (having had `const Vec3&` replaced with a texture pointer):


```
class Lambertian : public Material {
    public:
        Lambertian(const Vec3& a) : albedo(make_shared<SolidColor>(a)) {};
        Lambertian(shared_ptr<Texture> a) : albedo(a) {}

        virtual bool scatter(const Ray& rayIn, 
                            const HitRecord& rec, 
                            Vec3& attenuation, 
                            Ray& scattered) const {
            Vec3 scatterDirection = rec.p + rec.normal + randomUnitVector();
            scattered = Ray(rec.p, scatterDirection - rec.p, rayIn.moment());
            attenuation = albedo->value(rec.u, rec.v, rec.p);
            return true;
        }
    shared_ptr<Texture> albedo; // reflectivity

};
```

> From the hitpoint P, we compute the surface coordinates (u,v). We then use these to index into our procedural solid texture (like marble). We can also read in an image and use the 2D (u,v) texture coordinate to index into the image. 

UV coordinates more convenient to use than raw pixel coordinates, as the coordinates are normalized to [0,1] and are resolution-independent. For pixel (i,j) in an nx∗ny image, the UV coordinates are:

$$
u = i / (nx - 1)\\
v = j / (ny - 1)
$$

#### Using Images as Textures
To use images as textures, we're going to create a class that takes advantage of Shirley's favorite image utility - [stb_image](https://github.com/nothings/stb).

> It reads image data into a big array of unsigned chars. These are just packed RGBs with each component in the range [0,255] (black to full white). To help make loading our image files even easier, we provide a helper class to manage all this — rtw_image. The following listing assumes that you have copied the [stb_image.h](https://github.com/nothings/stb/blob/master/stb_image.h) header into a folder called external. Adjust according to your directory structure.

```cpp
#ifndef RTW_STB_IMAGE_H
#define RTW_STB_IMAGE_H

// Disable strict warnings for this header from the Microsoft Visual C++ compiler.
#ifdef _MSC_VER
    #pragma warning (push, 0)
#endif

#define STB_IMAGE_IMPLEMENTATION
#define STBI_FAILURE_USERMSG
#include "../external/stb_image.h"

#include <cstdlib>
#include <iostream>

class rtw_image {
  public:
    rtw_image() : data(nullptr) {}

    rtw_image(const char* image_filename) {
        // Loads image data from the specified file. If the RTW_IMAGES environment variable is
        // defined, looks only in that directory for the image file. If the image was not found,
        // searches for the specified image file first from the current directory, then in the
        // images/ subdirectory, then the _parent's_ images/ subdirectory, and then _that_
        // parent, on so on, for six levels up. If the image was not loaded successfully,
        // width() and height() will return 0.

        auto filename = std::string(image_filename);
        auto imagedir = getenv("RTW_IMAGES");

        // Hunt for the image file in some likely locations.
        if (imagedir && load(std::string(imagedir) + "/" + image_filename)) return;
        if (load(filename)) return;
        if (load("images/" + filename)) return;
        if (load("../images/" + filename)) return;
        if (load("../../images/" + filename)) return;
        if (load("../../../images/" + filename)) return;
        if (load("../../../../images/" + filename)) return;
        if (load("../../../../../images/" + filename)) return;
        if (load("../../../../../../images/" + filename)) return;

        std::cerr << "ERROR: Could not load image file '" << image_filename << "'.\n";
    }

    ~rtw_image() { STBI_FREE(data); }

    bool load(const std::string filename) {
        // Loads image data from the given file name. Returns true if the load succeeded.
        auto n = bytes_per_pixel; // Dummy out parameter: original components per pixel
        data = stbi_load(filename.c_str(), &image_width, &image_height, &n, bytes_per_pixel);
        bytes_per_scanline = image_width * bytes_per_pixel;
        return data != nullptr;
    }

    int width()  const { return (data == nullptr) ? 0 : image_width; }
    int height() const { return (data == nullptr) ? 0 : image_height; }

    const unsigned char* pixel_data(int x, int y) const {
        // Return the address of the three bytes of the pixel at x,y (or magenta if no data).
        static unsigned char magenta[] = { 255, 0, 255 };
        if (data == nullptr) return magenta;

        x = clamp(x, 0, image_width);
        y = clamp(y, 0, image_height);

        return data + y*bytes_per_scanline + x*bytes_per_pixel;
    }

  private:
    const int bytes_per_pixel = 3;
    unsigned char *data;
    int image_width, image_height;
    int bytes_per_scanline;

    static int clamp(int x, int low, int high) {
        // Return the value clamped to the range [low, high).
        if (x < low) return low;
        if (x < high) return x;
        return high - 1;
    }
};

// Restore MSVC compiler warnings
#ifdef _MSC_VER
    #pragma warning (pop)
#endif

#endif
```

Now that we've got `stb_image` in the mix, we can create our `ImageTexture` class in `Texture.h`:

```cpp
#include "Interval.h"
#include "rtw_stb_image.h"

...

class ImageTexture : public Texture {
    public:
        ImageTexture(const char* filename) : image(filename) {}

        Vec3 value(double u, double v, const Vec3& p) const override {
            // If we have no texture data, then return solid cyan as a debugging aid.
            if (image.height() <= 0) return Vec3(0,1,1);

            // Clamp input texture coordinates to [0,1] x [1,0]
            u = Interval(0,1).clamp(u);
            v = 1.0 - Interval(0,1).clamp(v);  // Flip V to image coordinates

            auto i = static_cast<int>(u * image.width());
            auto j = static_cast<int>(v * image.height());
            auto pixel = image.pixel_data(i,j);

            auto colorScale = 1.0 / 255.0;
            return Vec3(colorScale*pixel[0], colorScale*pixel[1], colorScale*pixel[2]);
        }

    private:
        rtw_image image;
};

```

We'll use the suggested earth map for our first uv-mapped render:

[Earth map](/assets/images/blog-images/path-tracer/the-next-week/earthmap.jpg)

Let's add an earth render to `Main.cpp`:

```cpp
void generateEarth() {
    HittableList world;

    auto earthTexture = make_shared<ImageTexture>("earthmap.jpg");
    auto earthSurface = make_shared<Lambertian>(earthTexture);
    auto globe = make_shared<Sphere>(Vec3(0,0,0), 2, earthSurface);

    world.add(globe);

    Camera cam;

    cam.aspectRatio         = 16.0 / 9.0;
    cam.samplesPerPixel     = 100;
    cam.maxDepth            = 50;

    cam.vFov                = 20;
    cam.lookFrom            = Vec3(0,0,12);
    cam.lookAt              = Vec3(0,0,0);
    cam.upDirection         = Vec3(0,1,0);


    cam.render(world);
}
```

![Our first image texture render - the pale blue dot](/assets/images/blog-images/path-tracer/the-next-week/earth.png)

### Using Noise
Noise is invaluable in computer graphics (and many other fields). You may have heard of [white noise](https://en.wikipedia.org/wiki/White_noise) - but have you heard of [Perlin noise](https://en.wikipedia.org/wiki/Perlin_noise)? It was developed in 1983 due to Ken Perlin's frustration with the machine-like look of CGI at the time. To simplify, Perlin noise essentially "looks" like blurry white noise:

![White noise](/assets/images/blog-images/path-tracer/the-next-week/white-noise.png)

![Perlin noise](/assets/images/blog-images/path-tracer/the-next-week/perlin-noise.png)

There are a few important aspects of Perlin noise:
- it's repeatable
- nearby points return similar values
- it's simple & fast

I find Shirley's walkthrough on noise to be a bit too fast and loose. [This series](https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/procedural-patterns-noise-part-1/introduction.html)(Wow), [this article](https://rtouti.github.io/graphics/perlin-noise-algorithm), and [this article](http://eastfarthing.com/blog/2015-04-21-noise/) will help illustrate aspects of Perlin noise covered in the next few sections.

To start implementing noise, let's create a new class - `Perlin.h`. We'll start by simply scrambling some random numbers (This is not Perlin noise yet!):

```cpp

#ifndef PERLIN_H
#define PERLIN_H

#include "RtWeekend.h"

class Perlin {
  public:
    Perlin() {
        randomDouble = new double[pointCount];
        for (int i = 0; i < pointCount; ++i) {
            randomDouble[i] = RT_WEEKEND_H::randomDouble();
        }

        permX = perlinGeneratePerm();
        permY = perlinGeneratePerm();
        permZ = perlinGeneratePerm();
    }

    ~Perlin() {
        delete[] randomDouble;
        delete[] permX;
        delete[] permY;
        delete[] permZ;
    }

    double getNoise(const Vec3& p) const {
        auto i = static_cast<int>(4*p.x()) & 255;
        auto j = static_cast<int>(4*p.y()) & 255;
        auto k = static_cast<int>(4*p.z()) & 255;

        return randomDouble[permX[i] ^ permY[j] ^ permZ[k]];
    }

  private:
    static const int pointCount = 256;
    double* randomDouble;
    int* permX;
    int* permY;
    int* permZ;

    static int* perlinGeneratePerm() {
        auto p = new int[pointCount];

        for (int i = 0; i < Perlin::pointCount; i++)
            p[i] = i;

        permute(p, pointCount);

        return p;
    }

    static void permute(int* p, int n) {
        for (int i = n-1; i > 0; i--) {
            int target = randomInt(0, i);
            int tmp = p[i];
            p[i] = p[target];
            p[target] = tmp;
        }
    }
};

#endif

```

From here, we'll create a `NoiseTexture` class:

`Texture.h`:
```cpp

#include "Perlin.h"

...

class NoiseTexture : public Texture {
    public:
        NoiseTexture() {}

        Vec3 value(double u, double v, const Vec3& p) const override {
            return Vec3(1,1,1) * perlin.getNoise(p);
        }

    private:
        Perlin perlin;

};

```

Let's use our hashed texture on some spheres:

`Main.h`:
```cpp
...

void generateTwoPerlinSpheres() {
    HittableList world;

    auto perlinTexture = make_shared<NoiseTexture>();
    world.add(make_shared<Sphere>(Vec3(0,-1000,0), 1000, make_shared<Lambertian>(perlinTexture)));
    world.add(make_shared<Sphere>(Vec3(0,2,0), 2, make_shared<Lambertian>(perlinTexture)));

    Camera cam;

    cam.aspectRatio        = 16.0 / 9.0;
    cam.samplesPerPixel    = 100;
    cam.maxDepth           = 50;

    cam.vFov               = 20;
    cam.lookFrom           = Vec3(13,2,3);
    cam.lookAt             = Vec3(0,0,0);
    cam.upDirection        = Vec3(0,1,0);

    cam.render(world);
}

```

![Two noisy spheres (not Perlin yet!)](/assets/images/blog-images/path-tracer/the-next-week/noisy-spheres.png)

#### Smoothing our Noisy Spheres
Remember linear interpolation from the [first weekend]({{site.url}}/2020/06/19/ray-tracing-in-one-weekend-part-two.html) all those years ago? We'll implement the same thing with our noise function.

`Perlin.h`:

```cpp

    double getNoise(const Vec3& p) const {
            auto u = p.x() - floor(p.x());
            auto v = p.y() - floor(p.y());
            auto w = p.z() - floor(p.z());

            auto i = static_cast<int>(floor(p.x()));
            auto j = static_cast<int>(floor(p.y()));
            auto k = static_cast<int>(floor(p.z()));
            double c[2][2][2];

            for (int di=0; di < 2; di++)
                for (int dj=0; dj < 2; dj++)
                    for (int dk=0; dk < 2; dk++)
                        c[di][dj][dk] = randomDouble[
                            permX[(i+di) & 255] ^
                            permY[(j+dj) & 255] ^
                            permZ[(k+dk) & 255]
                        ];

            return trilinear_interpolation(c, u, v, w);
        }


...

private:

    static double trilinear_interpolation(double c[2][2][2], double u, double v, double w) {
        auto accum = 0.0;
        for (int i=0; i < 2; i++)
            for (int j=0; j < 2; j++)
                for (int k=0; k < 2; k++)
                    accum += (i*u + (1-i)*(1-u))*
                            (j*v + (1-j)*(1-v))*
                            (k*w + (1-k)*(1-w))*c[i][j][k];

        return accum;
    }

```

![Two noisy spheres "LERPed" (not Perlin yet!)](/assets/images/blog-images/path-tracer/the-next-week/noisy-spheres-lerped.png)

Note the sharp "gridding" in some areas. Some of this is due to [Mach banding](https://en.wikipedia.org/wiki/Mach_bands). A standard fix for this problem (according to Shirley) is to use a [Hermite cubic](https://en.wikipedia.org/wiki/Cubic_Hermite_spline) to round off the interpolation:

`Perlin.h`:
```cpp

double getNoise(const Vec3& p) const {
        auto u = p.x() - floor(p.x());
        auto v = p.y() - floor(p.y());
        auto w = p.z() - floor(p.z());

        // Hermite cubic
+       u = u*u*(3-2*u);
+       v = v*v*(3-2*v);
+       w = w*w*(3-2*w);

        auto i = static_cast<int>(floor(p.x()));
        auto j = static_cast<int>(floor(p.y()));
        auto k = static_cast<int>(floor(p.z()));
        double c[2][2][2];

        for (int di=0; di < 2; di++)
            for (int dj=0; dj < 2; dj++)
                for (int dk=0; dk < 2; dk++)
                    c[di][dj][dk] = randomDouble[
                        permX[(i+di) & 255] ^
                        permY[(j+dj) & 255] ^
                        permZ[(k+dk) & 255]
                    ];

        return trilinear_interpolation(c, u, v, w);
    }

```

![Two noisy spheres "LERPed" and Hermite'd (not Perlin yet!)](/assets/images/blog-images/path-tracer/the-next-week/noisy-spheres-lerped-hermitian.png)

#### Adjusting the Frequency

The frequency of the noise is pretty low here - we can scale the input point to adjust the variation:

`Texture.h`:

```cpp
...

class NoiseTexture : public Texture {
    public:
        NoiseTexture() {}

+       NoiseTexture(double scale) : scale(scale) {}

        Vec3 value(double u, double v, const Vec3& p) const override {
+           return Vec3(1,1,1) * perlin.getNoise(scale * p);
        }

    private:
        Perlin perlin;
+       double scale;

};

```

`Main.cpp`:
```cpp

void generateTwoPerlinSpheres() {
    HittableList world;

+   auto perlinTexture = make_shared<NoiseTexture>(4);
    world.add(make_shared<Sphere>(Vec3(0,-1000,0), 1000, make_shared<Lambertian>(perlinTexture)));
    world.add(make_shared<Sphere>(Vec3(0,2,0), 2, make_shared<Lambertian>(perlinTexture)));

    ...

    cam.render(world);
}

```

![Two noisy spheres with higher frequencies](/assets/images/blog-images/path-tracer/the-next-week/noisy-spheres-high-frequency.png)

#### Using Random Vectors on Lattice Points to Reduce Blockiness

TODO: Find a good video illustrating random vectors on the corners


The best explanation that I've found of what's going on in this section (because I don't want to write it myself) can be found [here](https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/perlin-noise-part-2/perlin-noise.html).

The explanation of our first changes from Shirley:
> This(The previous image) is still a bit blocky looking, probably because the min and max of the pattern always lands exactly on the integer x/y/z. Ken Perlin’s very clever trick was to instead put random unit vectors (instead of just doubles) on the lattice points, and use a dot product to move the min and max off the lattice. So, first we need to change the random doubles to random vectors. These vectors are any reasonable set of irregular directions, and I won't bother to make them exactly uniform: 

```cpp

class Perlin {
  public:
    Perlin() {
!       randomVector = new Vec3[pointCount];
        for (int i = 0; i < pointCount; ++i) {
!           randomVector[i] = unitVector(Vec3::random(-1, 1));
        }

        permX = perlinGeneratePerm();
        permY = perlinGeneratePerm();
        permZ = perlinGeneratePerm();
    }

    ~Perlin() {
!       delete[] randomVector;
        delete[] permX;
        delete[] permY;
        delete[] permZ;
    }

...

  private:
    static const int pointCount = 256;
!   Vec3* randomVector;
    int* permX;
    int* permY;
    int* permZ;


```

We now have to modify our `getNoise()` function:

```cpp
  double getNoise(const Vec3& p) const {
        auto u = p.x() - floor(p.x());
        auto v = p.y() - floor(p.y());
        auto w = p.z() - floor(p.z());


-        // Hermite cubic
-        u = u*u*(3-2*u);
-        v = v*v*(3-2*v);
-        w = w*w*(3-2*w);


        auto i = static_cast<int>(floor(p.x()));
        auto j = static_cast<int>(floor(p.y()));
        auto k = static_cast<int>(floor(p.z()));
!        Vec3 c[2][2][2];

        for (int di=0; di < 2; di++)
            for (int dj=0; dj < 2; dj++)
                for (int dk=0; dk < 2; dk++)
!                    c[di][dj][dk] = randomVector[
                        permX[(i+di) & 255] ^
                        permY[(j+dj) & 255] ^
                        permZ[(k+dk) & 255]
                    ];

!        return perlinInterpolate(c, u, v, w);
    }

```

Note that I renamed `trilinearInterpolate` - let's go over its changes now:

```cpp

static double   perlinInterpolate(Vec3 c[2][2][2], double u, double v, double w) {
+   auto uu = u*u*(3-2*u);
+   auto vv = v*v*(3-2*v);
+   auto ww = w*w*(3-2*w);
    auto accum = 0.0;

    for (int i=0; i < 2; i++)
        for (int j=0; j < 2; j++)
            for (int k=0; k < 2; k++) {
!               Vec3 weightV(u-i, v-j, w-k);
!               accum += (i*uu + (1-i)*(1-uu))
!                       * (j*vv + (1-j)*(1-vv))
!                       * (k*ww + (1-k)*(1-ww))
!                       * dot(c[i][j][k], weightV);
            }

    return accum;
}

```

When performing Perlin interpolation, negative values can be returned, which will eventually be passed to `sqrt()` in our gamma function, breaking everything. To avoid this, we'll cast our Perlin output to a value between 0 and 1: 

```cpp

class NoiseTexture : public Texture {
    public:
        NoiseTexture() {}

        NoiseTexture(double scale) : scale(scale) {}

        Vec3 value(double u, double v, const Vec3& p) const override {
-           return Vec3(1,1,1) * perlin.getNoise(scale * p);
+           return Vec3(1,1,1) * 0.5 * (1.0 + perlin.getNoise(scale * p));

        }

    private:
        Perlin perlin;
        double scale;

};

```

Finally - the output:

![Perlin spheres](/assets/images/blog-images/path-tracer/the-next-week/perlin-spheres.png)

#### Implementing Turbulence















<!-- 
Add `double u` and `double v` to our `HitRecord` struct to store the UV surace coordinates of the hit point (Wel'll cover this in more detail in the [next section](#uv-texture-coordinates)):

`Hittable.h`
```cpp
struct HitRecord {
	double t; // parameter of the ray that locates the intersection point
	
	// surface coordinates of the hit point(uv texture coordinates)
	double u;
	double v;

	Vec3 p; // intersection point
	Vec3 normal;
	bool frontface;
	shared_ptr<Material> materialptr;

	inline void setfacenormal(const Ray& r, const Vec3& outwardnormal) {
        frontface = dot(r.direction(), outwardnormal) < 0;
        normal = frontface ? outwardnormal : -outwardnormal;
    }
};
```

At this point, we can create textured materials by replacing `const Vec3& albedo` with a pointer to our new `Texture` class:

`Material.h`:
```cpp
// Matte surface
// Light that reflects off a diffuse surface has its direction randomized.
// Light may also be absorbed. See Diffuse.png for illustration and detailed description
class Lambertian : public Material {
    public:
!       Lambertian(const Vec3& a) : albedo(make_shared<SolidColor>(a)) {};
!		Lambertian(shared_ptr<Texture> a) : albedo(a) {};

        virtual bool scatter(const Ray& rayIn, 
                            const HitRecord& rec, 
                            Vec3& attenuation, 
                            Ray& scattered) const {
            Vec3 scatterDirection = rec.p + rec.normal + randomUnitVector();
            scattered = Ray(rec.p, scatterDirection - rec.p, rayIn.moment());
!           attenuation = albedo->value(rec.u, rec.v, rec.p);
            return true;
        }
!	shared_ptr<Texture> albedo; // reflectivity

};
```

#### UV Texture Coordinates




The first order of business is to convert the raw pixel coordinates to normalized UV coordinates within $ [0, 1] $ to avoid any issues with varying texture size. For pixel $ (i, j) $ in an $ nx * ny $ image, the UV coordinates are:

$$

u=i/(nx−1)\\
v=j/(ny−1)

$$

We'll have to relate these UV coordinates to the $ (x,y,z) $ hit-point coordinates. To do so, we'll use spherical coordinates $ (\theta, \phi) $ - latitude and longitude. *Theta*($\theta$) - is the angle down from the north pole of the sphere. *Phi*($\phi$) - is the angle around the axis. The hit-point coordinates can be represented as:

$$
x=\cos(ϕ)\cos(θ)\\ 
y=\sin(ϕ)\cos(θ)\\
z=\sin(θ)
$$

To get the $ (\theta, \phi) $ coordinates, the equations above have to be [inverted](https://www.mathsisfun.com/algebra/trig-inverse-sin-cos-tan.html) using $ \arcsin $ and $ \arctan $. These functions (like [atan2](https://en.wikipedia.org/wiki/Atan2)) can be found in `<cmath>`. The angles returned will fall within $ -\frac{\pi}{2} $ and $ \frac{\pi}{2} $

$$ \phi = atan2(y,x) $$

$$ \theta = \arcsin(z) $$


After normalizing to $ [0,1] $, we get the following:

$$ u = \frac{\phi}{2\pi} $$

$$ v = \frac{\theta}{\pi} $$


We can add the $ (u,v) $ coordinate computation to a utility function in `Sphere.h`:
```cpp
void Sphere::getUvCoordinates(const Vec3& p, float& u, float& v){
	float phi = atan2(p.z(), p.x());
	float theta = asin(p.y());
	u = 1 - (phi + M_PI) / (2 * M_PI);
	v = (theta + M_PI / 2) / M_PI;
}
```


---

#### Reading an Texture/Image
 -->












<!-- Anyway, the first order of business is to compute spherical coordinates (think latitude and longitude). These will be $ (\theta, \phi) $ - $ \theta $ (*theta*) is the angle upwards from the south pole($ -y $) of the sphere. $ \phi $ (*phi*) is the angle around the y-axis - Imagine a flight right along the equator from Ecuador($ -x $) heading east - it'll pass over $ +z $, then $ +x $, then $ -z $, and will end up back home at $ -x $.

$ \theta $ and $ \phi $ need to be mapped to texture coordinates $ u $ and $ v $ in $ [0,1] $ where $ (u=0, v=0) $ maps to the bottom-left corner of the texture. As such, the normalization from $ (\theta, \phi) $ to $ (u, v) $ would be:

$$ u = \frac{\phi}{2\pi} $$
$$ v = \frac{\theta}{\pi} $$

![Spherical UV Mapping](/assets/images/blog-images/path-tracer/the-next-week/uv-mapping-sphere.gif) 
https://amycoders.org/tutorials/tm_approx.html   -->





<!-- 


We'll have to translate these two-dimensional points to hit points on our spheres; for that, we'll use spherical coordinates (theta $ \theta $ and phi $ \phi $). $ \theta $ is the angle south from the north pole, and $ \phi $ is the angle around the axis through the pole. In case you didn't notice, the mathematical symbols align quite nicely with these definitions. The hit point coordinates can be represented as such:

$$ x = \cos(\phi) * \cos(\theta) $$

$$ y = \sin(\phi) * \cos(\theta) $$

$$ z =  \sin(\theta) $$

To get the $ (\theta, \phi) $ coordinates, the equations above have to be [inverted](https://www.mathsisfun.com/algebra/trig-inverse-sin-cos-tan.html) using $ \arcsin $ and $ \arctan $. These functions (like [atan2](https://en.wikipedia.org/wiki/Atan2)) can be found in `<cmath>`. The angles returned will fall within $ -\frac{\pi}{2} $ and $ \frac{\pi}{2} $

$$ \phi = atan2(y,x) $$

$$ \theta = \arcsin(z) $$


After normalizing to $ [0,1] $, we get the following:

$$ u = \frac{\phi}{2\pi} $$

$$ v = \frac{\theta}{\pi} $$

We can add the $ (u,v) $ coordinate computation to a utility function in `Sphere.h`:
```cpp
class Sphere : public Hittable {

}
``` -->



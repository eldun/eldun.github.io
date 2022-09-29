---
title: "Ray Tracing in One Weekend:"
subtitle: "Part Three - The Next Weekend"
use-math: true
use-raw-images: false
layout: post
author: Evan
header-image: /assets\images\blog-images\path-tracer-part-three\
header-image-alt: 
header-image-title: 
tags: graphics ray-tracing-in-one-weekend c++
---

<a id="continue-reading-point"></a>
We've created a [straight-forward ray tracer]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#post-title) - what more could there be to do? By the time we're done with this segment, we'll have what Peter Shirley calls a "real ray tracer."

<!--end-excerpt-->

{% include ray-tracing/disclaimer.html %}

---
## Contents


{% include ray-tracing/part-nav.html %}

<ul class="table-of-contents">
    <li><a href="#motion-blur">Motion Blur</a></li>
        <ul>
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
        </ul>


</ul>

---

## <a id="motion-blur"></a>Motion Blur

Similarly to how we simulated [depth of field]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#depth-of-field) and [imperfect reflections]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#fuzzy-metal) through brute force in my [previous ray tracing post]({% link _posts/path-tracer/2020-06-19-ray-tracing-in-one-weekend-part-two.md %}), we can also implement motion blur.

[Motion blur] (in a real, physical camera) is a the result of movement while the camera's shutter is open. The image produced is the average of what the camera "saw" over that amount of time.

<span class="captioned-image">
![shutter-speed](/assets/images/blog-images/path-tracer/the-next-week/shutter.webp)
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
	...
	class camera
	{
	public:
		camera(vec3 lookFrom, vec3 lookAt, vec3 vUp, double vFov, double aspectRatio,
+			double aperture, double focusDistance, double shutterOpenDuration)
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
		sphere(vec3 center, float radius, material *material) : 
+			centerStart(center), 
+			centerEnd(center), 
+			moveStartTime(0),
+			moveEndTime(0),
			radius(radius), 
			material_ptr(material){};

+		// Moving sphere
+		sphere(vec3 centerStart, vec3 centerEnd, double timeToTravel, float radius, material *material) : 
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
		material *material_ptr;
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

+	vec3 sphere::centerAt(double time) const {
+
+		// Prevent divide by zero(naN) for static spheres
+		if (moveStartTime == moveEndTime) {
+			return centerStart;
+		}
+
+		else if (time < moveStartTime){
+			return centerStart;
+		}
+
+		else if (time > moveEndTime){
+			return centerEnd;
+		}
+
+		else 
+			return centerStart + ((time - moveStartTime) / (moveEndTime-moveStartTime))*+(centerEnd - centerStart);	
+	}
}</code></pre>

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
+        scattered = ray(rec.p, reflected + fuzz*random_unit_sphere_coordinate(), ray_in.moment()); // large spheres or grazing rays may go below the surface. In that case, they'll just be absorbed.
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

In the time since I've completed [The First Weekend]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html), Shirley has updated his code to use smart pointers in place of raw ones. Granted, I should've known to use smart pointers myself, but I was more familiar with java at that time and wanted to stick to the guide.

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
-		material* material_ptr;
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
-	hittable_list(hittable** l, int n) { list = l; list_size = n; }
+	hittable_list(shared_ptr&lt;hittable> object) {  }

+	void clear() { objects.clear(); }
+   void add(shared_ptr&lt;hittable> object) { objects.push_back(object); }
	virtual bool hit(const ray& r, double tmin, double tmax, hit_record& rec) const;

-	hittable** list;
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
-		sphere(vec3 center, float radius, material *material) : 
+		sphere(vec3 center, float radius, shared_ptr&lt;material> material) : 
			centerStart(center), 
			centerEnd(center), 
			moveStartTime(0),
			moveEndTime(0),
			radius(radius), 
			material_ptr(material){};

		// Moving sphere
-			sphere(vec3 centerStart, vec3 centerEnd, double timeToTravel, float radius, material *material) : 
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
-		material *material_ptr;
+		shared_ptr&lt;material> material_ptr;
	};

	...

</code></pre>

The changes for `Main.cpp` mostly amount to replacing all uses of keyword `new` with `make_shared`.

`Main.cpp`:

<pre><code class="language-diff-cpp diff-highlight">
...
-	vec3 color(const ray& r, hittable *world, int depth) {
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


-	hittable *random_scene() {
-    int n = 500;
-    hittable **list = new hittable*[n+1];
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

-	hittable *world = random_scene();
+	auto world = random_scene();

	...

}
</code></pre>


### <a id="setting-our-scene"></a>Setting our Scene
Okay - we've got all the boring maintenence out of the way. Do whatever you please; I simplified the scene to show off our new feature with a black sphere moving from left to right:

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
			int ir = int(255.99 * col[0]);
			int ig = int(255.99 * col[1]);
			int ib = int(255.99 * col[2]);
			std::cout &lt;&lt; ir &lt;&lt; " " &lt;&lt; ig &lt;&lt; " " &lt;&lt; ib &lt;&lt; "\n";
		}
	}
    
	...

}

</code></pre>

---

## <a id="bounding-volume-hierarchies"></a>Bounding Volume Hierarchies

<img alt="BVH Illustration" src="/assets/images/blog-images/path-tracer/the-next-week/bounding-volume-hierarchy-wikipedia.svg" style="background: white; padding: 2rem;">

Shirley describes this section as the most difficult part - he justfies tackling it now to avoid future refactoring in addition to significantly reducing runtime. Let's dive in.

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

![BVH Illustration](/assets/images/blog-images/path-tracer/the-next-week/bounding-hierarchies.png)

The orange & blue subsets are simply inside the white rectangle and the binary tree has no order. The pseudo-code for this hierarchy would look like:

</code></pre>
if (hits white)
    hitOrange = hits orange enclosed objects
    hitBlue = hits blue enclosed objects
    if (hitOrange or hitBlue)
        return true and info of closer hit
return false
</code></pre>

### <a id="implementing-a-hierarchy-using-axis-aligned-bounding-boxes"></a>Implementing a Hierarchy Using Axis-Aligned Bounding Boxes

We want our bounding box collisions to be fast and as compact as possible. For this, we'll implement a popular solution - axis-aligned bounding boxes (AABB's). These boxes will be "parallelepipeds" - 3d parallelograms.

![Parallelpiped](/assets/images/blog-images/path-tracer/the-next-week/parallelepiped-wiki.svg)

Since these AABB's are simply containers for our renderable objects, we don't need any additional information about collisions (like normals, materials, or hit points).

To formulate our AABB's, we'll use the slab method. Here's an explanation from [pbr-book.org](https://pbr-book.org/3ed-2018/Shapes/Basic_Shape_Interface):

> One way to think of bounding boxes is as the intersection of three slabs, where a slab is the region of space between two parallel planes. To intersect a ray against a box, we intersect the ray against each of the box’s three slabs in turn.

<span class="row-fill">
	<span class="captioned-image">
    ![Slab Intersection](/assets/images/blog-images/path-tracer/the-next-week/ray-slab-intersect.svg)
	Slab Intersection (with normal $(1,0,0)$)
	</span>
	<span class="captioned-image">
	![AABB Intersection](/assets/images/blog-images/path-tracer/the-next-week/ray-aabb-intersect.svg)
	2D AABB Intersection
	</span>
</span>



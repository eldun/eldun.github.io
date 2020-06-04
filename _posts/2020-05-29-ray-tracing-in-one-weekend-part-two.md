---
title: "Ray Tracing in One Weekend:"
subtitle: "Part Two - The First Weekend"
layout: post
author: Evan
header-image: /assets/images/blog-images/path-tracer/finished-product.png
header-image-alt: Path traced sphere scene render.
header-image-title: Render of a sphere-filled scene with diffuse, metallic, and dielectric materials.
tags: graphics ray-tracing ray-tracing-in-one-weekend c++
---

<a id="continue-reading-point"></a>
Now that we're familiar with ray tracing through [my introduction]({{ site.url }}/2020/05/20/ray-tracing-in-one-weekend-part-one#post-title), I'll delve into the titular first section of Peter Shirley's book.

<!--end-excerpt-->

---
## Contents
{% include ray-tracing-part-nav.html %}


<ul class="table-of-contents">
    <li><a href="#image-output"></a></li>
</ul>

---

## <a id="image-output"></a>Image Output
Of course, the first step with producing a pretty path traced image is to produce an image. The method suggested by Peter is a simple plaintext `.ppm` file. The following is an example snippet and image from [WikiPedia](https://en.wikipedia.org/wiki/Netpbm#PPM_example):

```
P3
3 2
255
# The part above is the header
# "P3" means this is a RGB color image in ASCII
# "3 2" is the width and height of the image in pixels
# "255" is the maximum value for each color
# The part below is image data: RGB triplets
255   0   0  # red
  0 255   0  # green
  0   0 255  # blue
255 255   0  # yellow
255 255 255  # white
  0   0   0  # black
  ```

![PPM Output](\assets\images\blog-images\path-tracer-part-two\ppm-example-output.png)

The code for creating a `.ppm` file is as follows:

`main.cpp`:
```
#include <iostream>

int main() {
	int nx = 200; // Number of horizontal pixels
	int ny = 100; // Number of vertical pixels
	std::cout << "P3\n" << nx << " " << ny << "\n255\n"; // P3 signifies ASCII, 255 signifies max color value
	for (int j = ny - 1; j >= 0; j--) { // Navigate canvas
		for (int i = 0; i < nx; i++) {
			float r = float(i) / float(nx);
			float g = float(j) / float(ny);
			float b = 0.2;
			int ir = int(255.99 * r);
			int ig = int(255.99 * g);
			int ib = int(255.99 * b);
			std::cout << ir << " " << ig << " " << ib << "\n";
		}
	}
}
```

Note:

- Pixels are written from left to right.
- Rows of pixels are written top to bottom.
- In this simple example, from left to right, red goes from 0 to 255. Green goes from 0 to 255, bottom to top. As such, the top right corner should be yellow.

Now to compile and redirect the output of our program to a file:
```
g++ main.cpp
./a.out > hello.ppm
```

You may have to use a [web tool](http://www.cs.rhodes.edu/welshc/COMP141_F16/ppmReader.html) or download a file viewer to actually view the `.ppm` file as an image. Here's my resulting image and raw contents of the file:

<span class="image-row two-images">
![The "Hello World" of our path tracer](\assets\images\blog-images\path-tracer-part-two\renders\hello-world-ppm.png)
![The "Hello World" of our path tracer](\assets\images\blog-images\path-tracer-part-two\hello-world-ppm-raw.png)
</span>

---

## <a id="vec3-class"></a>Vec3 Class
![Vector](\assets\images\blog-images\path-tracer-part-two\vectors\vector.png)
Vectors! I feel like I haven't used these since high school math but they are **lovely**. If you need or want a refresher on vectors, make sure to read [this section](#vector-refresher). According to Peter Shirley, almost all graphics programs have some class(es) for storing geometric vectors and colors. In many cases, the vectors are four-dimensional to represent homogenous coordinates for geometry, or to represent the alpha transparency channel for color values. We'll be using three-dimensional coordinates, as that's all we really need to represent direction, color, location, offset, etc.

Here are the constructors and declarations of the functions we'll be using within `vec3.h`.

`vec3.h`:
```
#ifndef VEC3H
#define VEC3H

#include <math.h>
#include <stdlib.h>
#include <iostream>

// 3 dimensional vectors will be used for colors, locations, directions, offsets, etc.
class vec3 {
public:
	vec3() {}
	vec3(double e0, double e1, double e2) { e[0] = e0; e[1] = e1; e[2] = e2; }

	inline double x() const { return e[0]; }
	inline double y() const { return e[1]; }
	inline double z() const { return e[2]; }
	inline double r() const { return e[0]; }
	inline double g() const { return e[1]; }
	inline double b() const { return e[2]; }

	// return reference to current vec3 object
	inline const vec3& operator+() const { return *this; }

	// return opposite of vector when using '-'
	inline vec3 operator-() const { return vec3(-e[0], -e[1], -e[2]); }

	// return value or reference to value of vec3 at index i ( I believe)
	inline double operator[](int i) const { return e[i]; }
	inline double& operator[](int i) { return e[i]; };

	inline vec3& operator+=(const vec3& v2);
	inline vec3& operator-=(const vec3& v2);
	inline vec3& operator*=(const vec3& v2);
	inline vec3& operator/=(const vec3& v2);
	inline vec3& operator*=(const double t);
	inline vec3& operator/=(const double t);

	inline double length() const {
		return sqrt(e[0]*e[0] + e[1]*e[1] + e[2]*e[2]);
	}
	inline double squared_length() const {
		return e[0]*e[0] + e[1]*e[1] + e[2]*e[2];
	}
	inline void make_unit_vector();

	double e[3];
};

...
```

The next step in our vector class is to define our functions. Be very careful here! This is where I had a few minor typo issues that absolutely mangled the final image later in the project. It's not hard to see why; these are the lowest-level operations of vectors, which will simulate our light rays and their properties.

`vec3.h`:
```
...

// input output overloading
inline std::istream& operator>>(std::istream& is, vec3& t) {
	is >> t.e[0] >> t.e[1] >> t.e[2];
	return is;
}

inline std::ostream& operator<<(std::ostream& os, const vec3& t) {
	os << t.e[0] << " " << t.e[1] << " " << t.e[2];
	return os;
}


inline void vec3::make_unit_vector() {
	double k = 1.0 / sqrt(e[0]*e[0] + e[1]*e[1] + e[2]*e[2]);
	e[0] *= k;
	e[1] *= k;
	e[2] *= k;
}

inline vec3 operator+(const vec3& v1, const vec3& v2) {
	return vec3(v1.e[0] + v2.e[0], v1.e[1] + v2.e[1], v1.e[2] + v2.e[2]);
}

inline vec3 operator-(const vec3& v1, const vec3& v2) {
	return vec3(v1.e[0] - v2.e[0], v1.e[1] - v2.e[1], v1.e[2] - v2.e[2]);
}

inline vec3 operator*(const vec3& v1, const vec3& v2) {
	return vec3(v1.e[0] * v2.e[0], v1.e[1] * v2.e[1], v1.e[2] * v2.e[2]);
}

inline vec3 operator/(const vec3& v1, const vec3& v2) {
	return vec3(v1.e[0] / v2.e[0], v1.e[1] / v2.e[1], v1.e[2] / v2.e[2]);
}

inline vec3 operator*(double t, const vec3& v) {
	return vec3(t * v.e[0], t * v.e[1], t * v.e[2]);
}

inline vec3 operator/(const vec3 v, double t) {
	return vec3(v.e[0] / t, v.e[1] / t, v.e[2] / t);
}

inline vec3 operator*(const vec3& v, double t) {
	return vec3(t * v.e[0], t * v.e[1], t * v.e[2]);
}

// Dot product
inline double dot(const vec3& v1, const vec3& v2) {
	return
		v1.e[0] * v2.e[0]
		+ v1.e[1] * v2.e[1]
		+ v1.e[2] * v2.e[2];
}

// Cross product
inline vec3 cross(const vec3& v1, const vec3& v2) {
	return vec3(v1.e[1] * v2.e[2] - v1.e[2] * v2.e[1],
				v1.e[2] * v2.e[0] - v1.e[0] * v2.e[2],
				v1.e[0] * v2.e[1] - v1.e[1] * v2.e[0]);
}

inline vec3& vec3::operator+=(const vec3& v) {
	e[0] += v.e[0];
	e[1] += v.e[1];
	e[2] += v.e[2];
	return *this;
}
inline vec3& vec3::operator-=(const vec3& v) {
	e[0] -= v.e[0];
	e[1] -= v.e[1];
	e[2] -= v.e[2];
	return *this;
}

inline vec3& vec3::operator*=(const vec3& v) {
	e[0] *= v.e[0];
	e[1] *= v.e[1];
	e[2] *= v.e[2];
	return *this;
}

inline vec3& vec3::operator/=(const vec3& v) {
	e[0] /= v.e[0];
	e[1] /= v.e[1];
	e[2] /= v.e[2];
	return *this;
}

inline vec3& vec3::operator*=(const double t) {
	e[0] *= t;
	e[1] *= t;
	e[2] *= t;
	return *this;
}

inline vec3& vec3::operator/=(const double t) {
	double k = 1.0 / t;

	e[0] *= k;
	e[1] *= k;
	e[2] *= k;
	return *this;
}

inline vec3 unit_vector(vec3 v) {
	return v / v.length();
}

#endif // !VEC3H
```

Need a vector refresher? If so, check out [this rundown](https://www.mathsisfun.com/algebra/vectors.html) at mathisfun.com. It's the best I've found.
All the operations within the code above are covered the mathisfun post. Take particular note of [make_unit_vector()](https://www.mathsisfun.com/algebra/vector-unit.html), [dot()](https://www.mathsisfun.com/algebra/vectors-dot-product.html), and [cross()](https://www.mathsisfun.com/algebra/vectors-cross-product.html).

Make sure to include our new vec3.h in main.cpp.

`main.cpp`:
```
```#include <iostream>

<span class=highlight-green>
#include "vec3.h"
</span>

int main() {
	int nx = 200; // Number of horizontal pixels
	int ny = 100; // Number of vertical pixels
	std::cout << "P3\n" << nx << " " << ny << "\n255\n"; // P3 signifies ASCII, 255 signifies max color value
	for (int j = ny - 1; j >= 0; j--) { // Navigate canvas
		for (int i = 0; i < nx; i++) {
			<span class=highlight-green>
			vec3 col(float(i) / float(nx), float(j) / float(ny), 0.2);
			int ir = int(255.99 * col[0]);
			int ig = int(255.99 * col[1]);
			int ib = int(255.99 * col[2]);
			</span>
			std::cout << ir << " " << ig << " " << ib << "\n";
		}
	}

```  

## <a id="rays"></a>Rays
Ray tracers need rays! These are what will be colliding with objects in the scene. Rays have an origin and a direction, and can be described by the following formula:

***P***(*t*) = ***A*** + *t****B***

- ***p*** is a point on the ray.
- ***A*** is the ray origin.
- ***B*** is the direction of the ray.
- The ray parameter *t* is a real number (positive or negative) that moves ***p***(t) along the ray.

![Our Ray (Illustration from Peter Shirley's book)](\assets\images\blog-images\path-tracer-part-two\shirley\fig.lerp.png)

Here's the header file for our ray class:

`ray.h:`
```
#ifndef RAYH
#define RAYH
#include "Vec3.h"

class ray
{
public:
	ray() {}
	ray(const vec3& a, const vec3& b) { A = a; B = b; }
	vec3 origin() const		{ return A; }
	vec3 direction() const	{ return B; }
	vec3 point_at_parameter(double t) const { return A + t * B; }

	vec3 A;
	vec3 B;
};

#endif // !RAYH
```

## <a id="sending-rays"></a>Sending Rays
Put simply, our ray tracer will send rays through pixels and compute the color seen for each ray. The steps for doing so are as follows:

1. Calculate the ray from camera to pixel.
2. Determine which objects the ray intersects.
3. Compute a color for the intersection.

We will need a "viewport" of sorts to pass rays through from our "camera." Since we're using standard square pixel spacing, the viewport will have the same aspect ratio as our rendered image. Shirley sets the height of the viewport to two units in his book, and we'll do the same.

Using Peter Shirley's example, we're going to set the camera at (0,0,0), and look towards the negative z-axis. The viewport will be traversed with rays from left-to-right, bottom-to-top. Variables u and v will be the offset vectors used to move the camera ray along the viewport:
![Camera Geometry (Illustration from Peter Shirley's book)](\assets\images\blog-images\path-tracer-part-two\shirley\fig.cam-geom.png)

Here's our code for the camera, as well as rendering a blue-to-white gradient:

`main.cpp:`
```

#include <iostream>
#include "ray.h"

/*
* Linearly blends white and blue depending on the value of y coordinate (Linear Blend/Linear Interpolation/lerp).
* Lerps are always of the form: blended_value = (1-t)*start_value + t*end_value.
* t = 0.0 = White
* t = 1.0 = Blue
*/
vec3 color(const ray& r) {
	vec3 unit_direction = unit_vector(r.direction());
	double t = 0.5 * (unit_direction.y() + 1.0);
	return (1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0);

}

int main() {
	int nx = 200; // Number of horizontal pixels
	int ny = 100; // Number of vertical pixels
	std::cout << "P3\n" << nx << " " << ny << "\n255\n"; // P3 signifies ASCII, 255 signifies max color value

	// The values below are derived from making the "camera"/ray origin coordinates (0, 0, 0) relative to the canvas.
	vec3 lower_left_corner(-2.0, -1.0, -1.0);
	vec3 horizontal(4.0, 0.0, 0.0);
	vec3 vertical(0.0, 2.0, 0.0);
	vec3 origin(0.0, 0.0, 0.0);
	for (int j = ny - 1; j >= 0; j--) {
		for (int i = 0; i < nx; i++) {
			double u = double(i) / double(nx);
			double v = double(j) / double(ny);

			// Approximate pixel centers on the canvas for each ray r
			ray r(origin, lower_left_corner + u * horizontal + v * vertical);

			vec3 col = color(r);
			int ir = int(255.99 * col[0]);
			int ig = int(255.99 * col[1]);
			int ib = int(255.99 * col[2]);
			std::cout << ir << " " << ig << " " << ib << "\n";
		}
	}
}
```

The result:
![Linear Gradient](\assets\images\blog-images\path-tracer-part-two\renders\gradient.png)


## <a id="adding-a-sphere"></a>Adding a Sphere
We have a beautiful sky-like gradient. Let's add a sphere! Spheres are popular in ray tracers because they're mathematically simple.

A sphere centered at the origin of radius ***R*** is ***x***<sup>2</sup> + ***y***<sup>2</sup> + ***z***<sup>2</sup> = ***R***<sup>2</sup>.

- This means that if a point (x,y,z) is on a sphere, ***x***<sup>2</sup> + ***y***<sup>2</sup> + ***z***<sup>2</sup> = ***R***<sup>2</sup>.
- If the point is inside the sphere, ***x***<sup>2</sup> + ***y***<sup>2</sup> + ***z***<sup>2</sup> < ***R***<sup>2</sup>
- If the point is outside the sphere, ***x***<sup>2</sup> + ***y***<sup>2</sup> + ***z***<sup>2</sup> > ***R***<sup>2</sup>

If the sphere center isn't at the origin, the formula is:

(x−C<sub>x</sub>)<sup>2</sup>+(y−C<sub>y</sub>)<sup>2</sup>+(z−C<sub>z</sub>)<sup>2</sup>=r<sup>2</sup>


It's best if formulas are kept under the hood in the vec3 class.

The vector from center C=(C<sub>x</sub>,C<sub>y</sub>,C<sub>z</sub>) to point P=(x,y,z) is (P−C), and therefore
(P−C)⋅(P−C)=(x−C<sub>x</sub>)<sup>2</sup>+(y−C<sub>y</sub>)<sup>2</sup>+(z−C<sub>z</sub>)<sup>2</sup>

Therefore, the equation of a sphere in vector form is: 

(P−C)⋅(P−C)=r<sup>2</sup>

Any point P that satisfies this equation is on the sphere.
We're going to find out if a given ray *ever* hits the sphere. If it does, there is a value *t* for which P(t) satisfies this equation:

(P(t)−C)⋅(P(t)−C)=r<sup>2</sup>

The same formula, expanded:
(A+tb−C)⋅(A+tb−C)=r<sup>2</sup>

and again:
t<sup>2</sup>b⋅b+2tb⋅(A−C)+(A−C)⋅(A−C)−r<sup>2</sup>=0

The unknown variable is *t*, and this is a quadratic equation. Solving for *t* will lead to a square root operation (aka the discriminant) that is either positive (two real solutions), negative (no real solutions), or zero (one real solution):
![Ray-Sphere Intersections(Illustration from Peter Shirley's book)](\assets\images\blog-images\path-tracer-part-two\shirley\fig.ray-sphere.png)


## <a id="placing-a-sphere"></a>Placing a Sphere

Prepend `main.cpp`'s main function with the following to mathematically hard-code a sphere to be hit by rays:

`main.cpp:`
```
...

bool hit_sphere(const vec3& center, double radius, const ray& r) {
	vec3 oc = r.origin() - center;
	double a = dot(r.direction(), r.direction());
	double b = 2.0 * dot(oc, r.direction());
	double c = dot(oc, oc) - radius * radius;
	double discriminant = b*b - 4*a*c;
	return (discriminant > 0);
}

/*
* Linearly blends white and blue depending on the value of y coordinate (Linear Blend/Linear Interpolation/lerp).
* Lerps are always of the form: blended_value = (1-t)*start_value + t*end_value.
* t = 0.0 = White
* t = 1.0 = Blue
*/
vec3 color(const ray& r) {
	if (hit_sphere(vec3(0, 0, -1), 0.5, r))
		return vec3(1, 0, 0);
	vec3 unit_direction = unit_vector(r.direction());
	double t = 0.5 * (unit_direction.y() + 1.0);
	return (1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0);
}

...
```

The result:
![Ray traced sphere](\assets\images\blog-images\path-tracer-part-two\renders\red-sphere.png)

Be aware that if the sphere center is change to z= +1, we'll still see the same image. We should not be seeing objects behind us. This will be fixed in the next section.

## <a id="surface-normals-and-more-objects"></a>Surface Normals and More Objects

Our sphere looks like a circle. To make it a more obvious that it *is* a sphere, we'll add surface normals to the face. Surface normals are simply vectors that are perpendicular to the surface of an object.
![Surface Normal](\assets\images\blog-images\path-tracer-part-two\Normal_vectors_on_a_curved_surface.svg)

In our case, the outward normal is the hitpoint minus the center:
![Surface Normal(from Shirley's book)](\assets\images\blog-images\path-tracer-part-two\shirley\fig.sphere-normal.png)

Firstly, we'll have to change `hit_sphere()` to return a `double`, which will represent the distance to the intersecting point, instead of a simple `bool` indicating the intersection. In addition, since we don't have any lights, we can vizualize the normals with a color map.

Our main.cpp file will now look something like this:

`main.cpp:`
<pre><code>
#include &lt;iostream&gt;
#include "ray.h"

double hit_sphere(const vec3& center, double radius, const ray& r) {
	vec3 oc = r.origin() - center;
	double a = dot(r.direction(), r.direction());
	double b = 2.0 * dot(oc, r.direction());
	double c = dot(oc, oc) - radius * radius;
	double discriminant = (b*b) - (4*a*c);
	if (discriminant < 0) {
		return -1.0;
	}

<span class="highlight-green" markdown="1">
	else {
		return (-b - sqrt(discriminant)) / (2.0 * a);
</span>

	}
}

/*
* Assign colors to pixels
*
* Background -
* Linearly blends white and blue depending on the value of y coordinate (Linear Blend/Linear Interpolation/lerp).
* Lerps are always of the form: blended_value = (1-t)*start_value + t*end_value.
* t = 0.0 = White
* t = 1.0 = Blue
* 
* Draw sphere and surface normals
*/
vec3 color(const ray& r) {
	double t = hit_sphere(vec3(0, 0, -1), 0.5, r); // does the ray hit the values of a sphere placed at (0,0,-1) with a radius of .5?
	if (t > 0.0) { // sphere hit
		vec3 N = unit_vector(r.point_at_parameter(t) - vec3(0, 0, -1)); // N (the normal) is calculated
		return 0.5 * (vec3(N.x() + 1, N.y() + 1, N.z() + 1)); // RGB values assigned based on xyz values
	}
	vec3 unit_direction = unit_vector(r.direction());
	t = 0.5 * (unit_direction.y() + 1.0);
	return (1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0);

}

...
</code></pre>

Our resulting image:
![Sphere with Normals](\assets\images\blog-images\path-tracer-part-two\renders\surface-normals-render.png)


Cool! But it could be cooler. We need more spheres. The cleanest way to accomplish this is to create an abstract class - a class that must be overwritten by derived classes - of hittable objects.

Our hittable abstract class will have a "hit" function that will be passed a ray and a record containing information about the hit, such as the time(which will be added with motion blur later in this series), position, and the surface normal: 

`hittable.h:`
```
#ifndef HITTABLEH
#define HITTABLEH

#include "ray.h"


struct hit_record {
	double t;
	vec3 p;
	vec3 normal;
};

/* 
* A class for objects rays can hit.
*/
class hittable {
public: 
	virtual bool hit(const ray& r, double t_min, double t_max, hit_record& rec) const = 0;
};

#endif // !HITTABLEH
```


And a new file for our sphere:

`sphere.h:`
```
#ifndef SPHEREH
#define SPHEREH

#include "hittable.h"

class sphere : public hittable {
public:
	sphere() {}
	sphere(vec3 cen, float r) : center(cen), radius(r) {};
	virtual bool hit(const ray& r, double tmin, double tmax, hit_record& rec) const;
	vec3 center;
	double radius;
};

bool sphere::hit(const ray& r, double t_min, double t_max, hit_record& rec) const {
	vec3 oc = r.origin() - center; // Vector from center to ray origin
	double a = dot(r.direction(), r.direction());
	double b = dot(oc, r.direction());
	double c = dot(oc, oc) - radius*radius;
	double discriminant = (b * b) - (a * c);
	if (discriminant > 0) {
		double temp = (-b - sqrt(b * b - a * c)) / a; // quadratic
		if (temp < t_max && temp > t_min) {
			rec.t = temp;
			rec.p = r.point_at_parameter(rec.t);
			rec.normal = (rec.p - center) / radius;
			return true;
		}
		temp = (-b + sqrt(b * b - a * c)) / a;
		if (temp < t_max && temp > t_min) {
			rec.t = temp;
			rec.p = r.point_at_parameter(rec.t);
			rec.normal = (rec.p - center) / radius;
			return true;
		}
	}
	return false;
}

#endif // !SPHEREH
```

As well as a new file for a list of hittable objects:

`hittableList.h:`
```
#ifndef HITTABLELISTH
#define HITTABLELISTH

#include "hittable.h"

class hittable_list : public hittable {
public:
	hittable_list() {}
	hittable_list(hittable** l, int n) { list = l; list_size = n; }
	virtual bool hit(const ray& r, double tmin, double tmax, hit_record& rec) const;
	hittable** list;
	int list_size;
};

bool hittable_list::hit(const ray& r, double t_min, double t_max, hit_record& rec) const {
	hit_record temp_rec;
	bool hit_anything = false;
	double closest_so_far = t_max;
	for (int i = 0; i < list_size; i++) {
		if (list[i]->hit(r, t_min, closest_so_far, temp_rec)) {
			hit_anything = true;
			closest_so_far = temp_rec.t;
			rec = temp_rec;
		}
	}
	return hit_anything;
}

#endif // !HITTABLELISTH
```

And the modified `main.cpp`:

`main.cpp:`
```
#include <iostream>
#include "sphere.h"
#include "hittableList.h"
#include "float.h"

/****************************************************************************************
The code for this path tracer is based on "Ray Tracing in One Weekend" by Peter Shirley. 
				https://github.com/RayTracing/raytracing.github.io
*****************************************************************************************/


/*
* Assign colors to pixels
*
* Background -
* Linearly blends white and blue depending on the value of y coordinate (Linear Blend/Linear Interpolation/lerp).
* Lerps are always of the form: blended_value = (1-t)*start_value + t*end_value.
* t = 0.0 = White
* t = 1.0 = Blue
* 
* Draw sphere and surface normals
*/
vec3 color(const ray& r, hittable * world) {
	hit_record rec;
	if (world->hit(r, 0.0, DBL_MAX, rec)) {
		return 0.5 * vec3(rec.normal.x() + 1, rec.normal.y() + 1, rec.normal.z() + 1); // return a vector with values between 0 and 1 (based on xyz) to be converted to rgb values
	}
	else { // background
		vec3 unit_direction = unit_vector(r.direction());
		double t = 0.5 * (unit_direction.y() + 1.0);
		return (1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0);
	}
}

int main() {
	int nx = 200; // Number of horizontal pixels
	int ny = 100; // Number of vertical pixels
	std::cout << "P3\n" << nx << " " << ny << "\n255\n"; // P3 signifies ASCII, 255 signifies max color value

	// The values below are derived from making the "camera"/ray origin coordinates (0, 0, 0) relative to the canvas. 
	// See the included file "TracingIllustration.png" for a visual representation.
	vec3 lower_left_corner(-2.0, -1.0, -1.0);
	vec3 horizontal(4.0, 0.0, 0.0);
	vec3 vertical(0.0, 2.0, 0.0);
	vec3 origin(0.0, 0.0, 0.0);

	// Create spheres
	hittable *list[2];
	list[0] = new sphere(vec3(0, 0, -1), 0.5);
	list[1] = new sphere(vec3(0, -100.5, -1), 100);
	hittable* world = new hittable_list(list, 2);

	for (int j = ny - 1; j >= 0; j--) { // Navigate canvas
		for (int i = 0; i < nx; i++) {
			double u = double(i) / double(nx);
			double v = double(j) / double(ny);

			// Approximate pixel centers on the canvas for each ray r
			ray r(origin, lower_left_corner + u * horizontal + v * vertical);

			vec3 p = r.point_at_parameter(2.0);
			vec3 col = color(r, world);
			int ir = int(255.99 * col[0]);
			int ig = int(255.99 * col[1]);
			int ib = int(255.99 * col[2]);
			std::cout << ir << " " << ig << " " << ib << "\n";
		}
	}
}
```

The result:
![Sphere hittables](\assets\images\blog-images\path-tracer-part-two\renders\hittables.png)


Stunning. A little bit jaggedy, though, don't you think? This effect is known as "aliasing." If you wanted to, you could increase the resolution of our scene for higher fidelity. Another interesting method for better image quality falls under the umbrella term "anti-aliasing."

---

## <a id="anti-aliasing"></a>Anti-Aliasing
Anti-aliasing encompasses a whole slew of methods to combat "jaggies" - from multi-sampling to super-sampling, approximation(FXAA) to temporal, or - more recently - deep learning anti-aliasing. Each of these methods have pros and cons depending on the type of scene portrayed, performance targets, and even scene movement. Usually there's a trade-off between image quality and speed. We've entered a fascinating time for graphics where raw pixel count (True 4K this! Real 4K that!) is becoming less important - thanks to some incredible leaps in upscaling and anti-aliasing.

![Small sample of anti-aliasing methods](\assets\images\blog-images\path-tracer-part-two\anti-aliasing.png)

If you want to learn more, I highly suggest watching [this video](https://www.youtube.com/watch?v=NbrA4Nxd8Vo) from one of my favorite YouTube channels([Digital Foundry](https://www.youtube.com/user/DigitalFoundry)), or reading [this blog post](https://techguided.com/what-is-anti-aliasing/) from techguided.com.

We're going to be using multisample anti-aliasing (MSAA) in our ray tracer. As you may have supposed, multisampling in this case means taking multiple sub-pixel samples from each pixel and averaging the color across the whole pixel. Here's an example - the raw triangle on the left, and the triangle with four samples per pixel on the right:
<span class="image-row two-images">
![No MSAA](\assets\images\blog-images\path-tracer-part-two\no-msaa.png)
![MSAA 4x](\assets\images\blog-images\path-tracer-part-two\msaa.png)
</span>
[Source](https://developer.apple.com/documentation/metal/gpu_features/understanding_gpu_family_4/about_enhanced_msaa_and_imageblock_sample_coverage_control)

Instead of taking perfectly spaced samples of pixels like in the example above, we'll be taking random samples of pixels. For that, we'll need a way of generating random numbers (you can do it however you please):

`random.h:`
```
#ifndef RANDOMH
#define RANDOMH

#include <cstdlib>

inline double random_double() {
    // Returns a random real in [0,1).
    return rand() / (RAND_MAX + 1.0);
}

inline double random_double(double min, double max) {
    // Returns a random real in [min,max).
    return min + (max-min)*random_double();
}

#endif // !RANDOMH
```


Next, we'll create a camera class to manage the virtual camera and scene sampling:

```
#ifndef CAMERAH
#define CAMERAH

#include "ray.h"

class camera {
public:

	// The values below are derived from making the "camera" / ray origin coordinates(0, 0, 0) relative to the canvas.
	camera() {
		lower_left_corner = vec3(-2.0, -1.0, -1.0);
		horizontal = vec3(4.0, 0.0, 0.0);
		vertical = vec3(0.0, 2.0, 0.0);
		origin = vec3(0.0, 0.0, 0.0);
	}
	ray get_ray(double u, double v) { return ray(origin, lower_left_corner + u * horizontal + v * vertical - origin); }

	vec3 origin;
	vec3 lower_left_corner;
	vec3 horizontal;
	vec3 vertical;
};

#endif // !CAMERAH 
```
And our resulting main method:

`main.cpp:`
```
#include <iostream>
#include "sphere.h"
#include "hittableList.h"
#include "camera.h"
#include "random.h"


/*
* Assign colors to pixels
*
* Background -
* Linearly blends white and blue depending on the value of y coordinate (Linear Blend/Linear Interpolation/lerp).
* Lerps are always of the form: blended_value = (1-t)*start_value + t*end_value.
* t = 0.0 = White
* t = 1.0 = Blue
* 
*/
vec3 color(const ray& r, hittable * world) {
	hit_record rec;
	if (world->hit(r, 0.0, TMP_MAX, rec)) {
		return 0.5 * vec3(rec.normal.x() + 1, rec.normal.y() + 1, rec.normal.z() + 1); // return a vector with values between 0 and 1 (based on xyz) to be converted to rgb values
	}
	else { // background
		vec3 unit_direction = unit_vector(r.direction());
		double t = 0.5 * (unit_direction.y() + 1.0);
		return (1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0);
	}
}

int main() {

	int nx = 200; // Number of horizontal pixels
	int ny = 100; // Number of vertical pixels
	int ns = 100; // Number of samples for each pixel for anti-aliasing
	std::cout << "P3\n" << nx << " " << ny << "\n255\n"; // P3 signifies ASCII, 255 signifies max color value

	// Create spheres
	hittable *list[2];
	list[0] = new sphere(vec3(0, 0, -1), 0.5);
	list[1] = new sphere(vec3(0, -100.5, -1), 100);
	hittable* world = new hittable_list(list, 2);
	camera cam;

	for (int j = ny - 1; j >= 0; j--) { // Navigate canvas
		for (int i = 0; i < nx; i++) {
			vec3 col(0, 0, 0);
			for (int s = 0; s < ns; s++) { // Anti-aliasing - get ns samples for each pixel
				double u = (i + random_double(0.0, 1)) / double(nx);
				double v = (j + random_double(0.0, 1)) / double(ny);
				ray r = cam.get_ray(u, v);
				vec3 p = r.point_at_parameter(2.0);
				col += color(r, world);
			}

			col /= double(ns); // Average the color between objects/background
			int ir = int(255.99 * col[0]);
			int ig = int(255.99 * col[1]);
			int ib = int(255.99 * col[2]);
			std::cout << ir << " " << ig << " " << ib << "\n";
		}
	}
}
```

Keep in mind - these images are only 200x100.
The difference is clear. And blurry. Haha:
<span class = "image-row">
![Sphere hittables](\assets\images\blog-images\path-tracer-part-two\renders\hittables.png)
![Sphere hittables](\assets\images\blog-images\path-tracer-part-two\renders\hittables-msaa.png)
</span>
<span class = "image-row">
![Sphere hittables](\assets\images\blog-images\path-tracer-part-two\renders\hittables-zoom.png)
![Sphere hittables](\assets\images\blog-images\path-tracer-part-two\renders\hittables-msaa-zoom.png)
</span>

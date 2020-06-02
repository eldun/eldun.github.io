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
Now that we're familiar with ray tracing through [my introduction]( {{ site.url }}/2020/05/20/ray-tracing-in-one-weekend-part-one#post-title), I'll delve into the titular first section of Peter Shirley's book.

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
	int nx = 400; // Number of horizontal pixels
	int ny = 200; // Number of vertical pixels
	std::cout << "P3\n" << nx << " " << ny << "\n255\n"; // P3 signifies ASCII, 255 signifies max color value
	for (int j = ny - 1; j >= 0; j--) { // RGB triplets
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
![The "Hello World" of our path tracer](\assets\images\blog-images\path-tracer-part-two\hello-world-ppm.png)
![The "Hello World" of our path tracer](\assets\images\blog-images\path-tracer-part-two\hello-world-ppm-raw.png)
</span>

---

## <a id="vec3-class"></a>Vec3 Class
![Vector](\assets\images\blog-images\path-tracer-part-two\vector.png)
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

<!-- <a id="vector-refresher"></a>
(Compiled from [MathIsFun](https://www.mathsisfun.com/algebra/vectors.html))

Vectors have magnitude and direction:
![Vector](\assets\images\blog-images\path-tracer-part-two\vectors\vector-mag-dir.svg)

Vectors can be added by joining them "head-to-tail":
![Vector addition](\assets\images\blog-images\path-tracer-part-two\vectors\vector-add2.svg)

A real-world example:
![Vector addition airplane example](\assets\images\blog-images\path-tracer-part-two\vectors\vector-airplane.svg)

Vector subtraction, as with numbers, is adding a negative. First we reverse the direction of the vector to be subtracted, and then add them:
![Vector Addition](\assets\images\blog-images\path-tracer-part-two\vectors\vector-subtract.gif)

For calculations, vectors are split up into their x and y components:
![Vector addition airplane example](\assets\images\blog-images\path-tracer-part-two\vectors\vector-xy-components.gif)

We can then add the x and y components:
![Vector addition](\assets\images\blog-images\path-tracer-part-two\vectors\vector-add3.gif)

Magnitude of a vector is often represented as so:
|**a**|

The magnitude of a vector is calculated using Pythagoras' theorem with the x and y components:
|**a**| = sqrt(x^2 + y^2)

A vector with magnitude 1 is a known as a Unit Vector:
![Unit Vector](\assets\images\blog-images\path-tracer-part-two\vectors\vector-unit.svg)

Unit vectors are often represented by the hat symbol above their name. The unit vector of a vector a ("a-hat") is as follows:
**â**

Vectors can be "scaled" off the unit vector:
![Vector addition](\assets\images\blog-images\path-tracer-part-two\vectors\vector-unit-scale.gif)

Unit vectors can be used in two dimensions:
![Unit vector in two dimensions](\assets\images\blog-images\path-tracer-part-two\vectors\vector-unit-2d.gif)

As well as three dimensions:
![Unit vector in three dimensions](\assets\images\blog-images\path-tracer-part-two\vectors\vector-unit-3d.gif)

Scalars only have magnitude.

Multiplying a vector by a scalar is called "scaling" a vector.

Multiplying the vector **m** = (7,3) by the scalar 3:
![Vector scaling](\assets\images\blog-images\path-tracer-part-two\vectors\vector-scaling.gif)
**a** = 3**m** = (3×7, 3×3) = (21, 9)

Multiplying Vectors by Vectors (Dot Product and Cross Product) -->

Make sure to include our new vec3.h in main.cpp.

`main.cpp`:
```
#include <iostream>

int main() {
	int nx = 400; // Number of horizontal pixels
	int ny = 200; // Number of vertical pixels
	std::cout << "P3\n" << nx << " " << ny << "\n255\n"; // P3 signifies ASCII, 255 signifies max color value
	for (int j = ny - 1; j >= 0; j--) { // RGB triplets
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
  

## <a id="rays"></a>Rays
Ray tracers need rays! These are what will be colliding with objects in the scene. Rays have an origin and a direction, and be described by the following formula: 

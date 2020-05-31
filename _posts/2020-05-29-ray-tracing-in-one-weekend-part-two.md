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
Of course, the first step with producing a pretty path traced image is to produce *an* image. The method suggested by Peter is a simple plaintext `.ppm` file. The following is an example snippet and image from [WikiPedia](https://en.wikipedia.org/wiki/Netpbm#PPM_example):

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

You may have to use a [web tool](http://www.cs.rhodes.edu/welshc/COMP141_F16/ppmReader.html) or download a file viewer to actually view the `.ppm` file as an image. Here's my resulting image and raw contents of the file:

<span class="image-row two-images">
![The "Hello World" of our path tracer](\assets\images\blog-images\path-tracer-part-two\hello-world-ppm.png)
![The "Hello World" of our path tracer](\assets\images\blog-images\path-tracer-part-two\hello-world-ppm-raw.png)
</span>

---
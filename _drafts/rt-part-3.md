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
            <li href="#adapting-our-camera-class">Adapting our Camera Class</li>
			<li href="#creating-moving-spheres">Creating Moving Spheres</li>
            <li href="#adapting-our-material-class">Adapting our Material Class</li>
            <li href="#setting-our-scene">Setting our Scene</li>
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

Motion blur would be useless without motion. We can modify our spheres to move linearly from some point `centerStart` to another `centerEnd` over an amount of time `timeToTravel`. 

`sphere.h`:

<pre><code class="language-diff-cpp diff-highlight"> 
	class sphere : public hittable {
		public:
		sphere() {}
		sphere(vec3 center, float radius, material *material) : 
+			centerStart(center), 
+			centerEnd(center), 
+			timeToTravel(0), 
			radius(radius), 
			material_ptr(material){};

+		// Moving sphere
+		sphere(vec3 centerStart, vec3 centerEnd, double timeToTravel, float radius, material *material) : 
+			centerStart(centerStart),
+			centerEnd(centerEnd),
+			timeToTravel(timeToTravel), 
+			radius(radius), 
+			material_ptr(material){};

		virtual bool hit(const ray &r, double tmin, double tmax, hit_record &rec) const;

+		vec3 centerAt(double time) const;

+		vec3 centerStart, centerEnd;
+		double timeToTravel;
		double radius;
		material *material_ptr;
	};
	</code></pre>


Checking for a hit remains mostly the same - we just account for moving spheres by calculating the centers at specific times. If you need a refresher on the implementation details of sphere collisions, check [here]({{ site.url }}/2020/06/19/ray-tracing-in-one-weekend-part-two.html#simplifying-ray-sphere-intersection ).

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

			if (temp < t_max && temp > t_min) {
				rec.t = temp;
				rec.p = r.point_at_parameter(rec.t);
+				vec3 outward_normal = (rec.p - centerAt(r.moment())) / radius;
				rec.set_face_normal(r, outward_normal);
				rec.material_ptr = material_ptr;
				return true;
			}
			temp = (-halfB + root) / a;
			if (temp < t_max && temp > t_min) {
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
+		return centerStart + (time / timeToTravel) * (centerEnd - centerStart);
+	}
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

                if (reflect_random < reflect_probability) {
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


### <a id="setting-our-scene"></a>Setting our Scene


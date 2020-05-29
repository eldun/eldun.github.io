---
title: "Ray Tracing in One Weekend:"
subtitle: "Part One - an Introduction"
layout: post
author: Evan
header-image: /assets/images/blog-images/path-tracer/finishedProduct.png
header-image-alt: Path traced sphere scene render.
header-image-title: Render of a sphere-filled scene with diffuse, metallic, and dielectric materials.
tags: graphics ray-tracing ray-tracing-in-one-weekend
---

<a id="continue-reading-point"></a>
It took me long enough, but I finally dipped my toes into the temperate waters of computer graphics earlier this year.
Continue reading to learn about what ray tracing is and why I decided to explore it.

<!--end-excerpt-->

---
## Contents

<ul class="table-of-contents">
    <li><a href="#what-is-ray-tracing">What is Ray Tracing?</a></li>
    <li><a href="#what-is-path-tracing">What is Path Tracing?</a></li>
    <li><a href="#what-is-rasterization">What is Rasterization?</a></li>
    <li><a href="#a-happy-medium">A Happy Medium (For Now)</a></li>
    <li><a href="#practical-applications-of-ray-tracing">Practical Applications of Ray Tracing</a></li>
    <li><a href="#an-abbreviated-graphics-timeline">An Abbreviated Graphics Timeline</a></li>        <li><a href="#why-explore-ray-tracing">Why Explore Ray Tracing?</a></li>
    </ul>

---

## <a id="what-is-ray-tracing"></a>What is Ray Tracing?

<span class="image-row two-images">
![Minecraft (2011 Initial Release, 2020 Path Tracing Update)](/assets/images/blog-images/path-tracer/minecraft-ray-tracing-off.png)
![Minecraft (2011 Initial Release, 2020 Path Tracing Update)](/assets/images/blog-images/path-tracer/minecraft-ray-tracing-on.png)
</span>
Put simply, ray tracing is a rendering technique that can accurately simulate the lighting of a scene.

Ray tracing generates an image by determining the color of each pixel of the image in a mathematically formulated scene. In the simplest example, the color of each one of these pixels is determined by sending a ray from the camera into the scene, and back to its light source. 

The ray will potentially collide with - and bounce off of - scene objects. Each of these scene objects has intrinsic properties, such as reflectivity, refractive index, and roughness. The interactions of the ray among all these objects are combined with the light source to determine the final color and intensity of the pixel. This process is repeated for the whole image, pixel by pixel.

You may be thinking: "Why send a ray from the camera instead of from the light source?"
The reason is a matter of efficiency; rather than sending rays out from the light in all directions, it's much more effective to only trace the bare minimum - which in our simplistic example - is one ray for each pixel of the image.

![Ray Tracing Illustration](/assets/images/blog-images/path-tracer/ray-tracing-put-simply.png)

---

## <a id="what-is-path-tracing"></a>What is Path Tracing?
![Path traced glass dragon](/assets/images/blog-images/path-tracer/path-traced-dragon.png)

Path tracing is similar to ray tracing, but much more intensive. Hundreds to thousands of rays are traced through each pixel of the image, with numerous bounces off of - or through - objects, before reaching the light source (or hitting a specified "bounce limit") to generate more accurate color and lighting information.

![Minecraft (2011 Initial Release, 2020 Path Tracing Update)](/assets/images/blog-images/path-tracer/minecraft-ray-tracing-on-compilation.png)

Path tracing, as you may have guessed, is more accurate a simulation than ray tracing, simulating soft shadows, caustics, and global illumination. However, it is more "brute-force". Without enough rays through each pixel or simulated bounces for each ray, the final image will be ridden with noise.

Also - fun fact: I learned recently path tracing requires light sources to have physical size instead of "point lights" used in ray tracing or rasterized graphics... which brings me to my next point...

---

## <a id="what-is-rasterization"></a>What is Rasterization?
Rasterization is the [vast majority of games](#an-abbreviated-graphics-timeline) have used in years past to display 3D scenes on 2D screens. Using rasterization, objects are represented with virtual triangles (AKA: polygons). These triangles all have corners (AKA: vertices), and these vertices contain data of such attributes as position, color, texture, and the surface normal (orientation).

The triangles are eventually "converted" to pixels when being rendered. Each pixel can be assigned an initial color value from the data stored in the triangle vertices. Further pixel processing or “shading” including changing color based on how lights in the scene hit, and applying one or more textures, combine to generate the final color applied to a pixel. Rasterization is used in real-time computer graphics and while still computationally intensive, it is less so compared to ray tracing.

*(The following images are from rasterized game engines)*
<span class="image-row three-images">
    <!-- ![Nintendo 64 (1996 (North America))](/assets/images/blog-images/path-tracer/n64.png) -->
    ![Super Mario 64 (1996)](/assets/images/blog-images/path-tracer/mario.png)
    ![F-Zero X (1998)](/assets/images/blog-images/path-tracer/f-zero-x.png)
    ![The Legend of Zelda: Ocarina of Time (1998)](/assets/images/blog-images/path-tracer/zelda.png)
</span>
<span class="image-row three-images">
    <!-- ![Sony Playstation (1995 (North America)) with DualShock -->
    <!-- Controller](/assets/images/blog-images/path-tracer/playstation-2.png) -->
    ![Solid Snake of Metal Gear Solid (1998)](/assets/images/blog-images/path-tracer/metal-gear-solid.png)
    ![Crash Bandicoot (1996)](/assets/images/blog-images/path-tracer/crash-bandicoot.png)
    ![Tekken (1995)](/assets/images/blog-images/path-tracer/tekken.png)
</span>
![Assassin's Creed Unity (2015)](/assets/images/blog-images/path-tracer/ac-unity-rasterized.png)

---

## <a id="a-happy-medium"></a>A Happy Medium (For Now)
Rasterization and ray tracing can be combined! Rasterization can determine visible objects relatively quickly, while ray tracing can be used to improve the quality of reflections, refractions, and shadows.

![Hybrid ray tracing](/assets/images/blog-images/path-tracer/hybrid-ray-tracing.png)

---

## <a id="practical-applications-of-ray-tracing"></a>Practical Applications of Ray Tracing
Applications of ray tracing are many and varied:
- Real-time rendering (video games)
- Non-real-time rendering (film and television)
- Architecture / lighting design
- Engineering
- Acoustics modeling
- Radio propagation modeling
- Physics simulations

<span class="image-row">
![Control(2019)](/assets/images/blog-images/path-tracer/control-boots.png)
</span>
<span class="image-row two-images">
    ![Battlefield V(2018)](/assets/images/blog-images/path-tracer/battlefield-five-lobby.png)
    ![Battlefield V(2018)](/assets/images/blog-images/path-tracer/battlefield-five-street.png)
</span>
<span class="image-row">
![(2019)](/assets/images/blog-images/path-tracer/toy-story-four.png)
</span>
<span class="image-row two-images">
![(Ray traced building)](/assets/images/blog-images/path-tracer/building.png)
![Ray traced acoustics](/assets/images/blog-images/path-tracer/room-acoustics.png)
</span>
<span class="image-row">
![(Ray traced building)](/assets/images/blog-images/path-tracer/couch.png)
</span>

---

## <a id="an-abbreviated-graphics-timeline"></a>An Abbreviated Graphics Timeline
I was born in 1995 - an exciting year for computer graphics. *Toy Story* - the first entirely
computer-animated feature film - would be released. Homer Simpson, of *The Simpsons* fame, would be computer-animated for a *Treehouse of Horror* Halloween episode. The Sony Playstation would be released in the United States.

<span class="image-row two-images">
    ![Toy Story](/assets/images/blog-images/path-tracer/toy-story.png)
    ![Homer Simpson](/assets/images/blog-images/path-tracer/homer.png)
</span>
<span class="image-row">
![Playstation](/assets/images/blog-images/path-tracer/playstation-1.png)
</span>

Technology had come a long way since 1980's *Battlezone*, which with its wireframe vector graphics, was one of the first
big "3D" successes in any medium. Thankfully, I was able to play a version of Battlezone at a young age, and naturally
noticed (and took a major interest in) the increasing fidelity of computer-generated graphics growing up.

This took far too long to compile:
<span class="image-row">
![Battlezone(1980)](/assets/images/blog-images/path-tracer/graphics-timeline/battlezone.png)
</span>
<span class="image-row five-images">
    ![Missle Command(1980)](/assets/images/blog-images/path-tracer/graphics-timeline/missle-command.png)
    ![Donkey Kong(1981)](/assets/images/blog-images/path-tracer/graphics-timeline/donkey-kong.png)
    ![Tempest(1981)](/assets/images/blog-images/path-tracer/graphics-timeline/tempest.png)
    ![Pole Position(1982)](/assets/images/blog-images/path-tracer/graphics-timeline/pole-position.png)
    ![Mario Bros.(1983)](/assets/images/blog-images/path-tracer/graphics-timeline/mario-bros.png)
</span>
<span class="image-row five-images">
    ![Dragon's Lair(1983)](/assets/images/blog-images/path-tracer/graphics-timeline/dragons-lair.png)
    ![Marble Madness(1984)](/assets/images/blog-images/path-tracer/graphics-timeline/marble-madness.png)
    ![Paperboy(1985)](/assets/images/blog-images/path-tracer/graphics-timeline/paperboy.png)
    ![Super Mario Bros.(1985)](/assets/images/blog-images/path-tracer/graphics-timeline/smb.png)
    ![The Legend of Zelda(1986)](/assets/images/blog-images/path-tracer/graphics-timeline/legend-of-zelda.png)
</span>
<span class="image-row five-images">
    ![Metroid(1986)](/assets/images/blog-images/path-tracer/graphics-timeline/metroid.png)
    ![Castlevania II: Simon's Quest(1987)](/assets/images/blog-images/path-tracer/graphics-timeline/castlevania.png)
    ![Mike Tyson's Punch-Out(1987)](/assets/images/blog-images/path-tracer/graphics-timeline/punch-out.png)
    ![Mega Man 2(1988)](/assets/images/blog-images/path-tracer/graphics-timeline/mega-man.png)
    ![John Madden Football(1988)](/assets/images/blog-images/path-tracer/graphics-timeline/madden.png)
</span>
<span class="image-row four-images">
    ![SimCity(1989)](/assets/images/blog-images/path-tracer/graphics-timeline/sim-city.png)
    ![Super Mario Bros. 3(1990)](/assets/images/blog-images/path-tracer/graphics-timeline/smb-3.png)
    ![Super Mario World(1990)](/assets/images/blog-images/path-tracer/graphics-timeline/super-mario-world.png)
    ![F-Zero(1990)](/assets/images/blog-images/path-tracer/graphics-timeline/f-zero.png)
</span>
<span class="image-row">
    ![Another World(1991)](/assets/images/blog-images/path-tracer/graphics-timeline/another-world.png)
    </span>
<span class="image-row four-images">
    ![Wolfenstein 3D(1992)](/assets/images/blog-images/path-tracer/graphics-timeline/wolfenstein.png)
    ![Virtua Racing(1992)](/assets/images/blog-images/path-tracer/graphics-timeline/virtua-racing.png)
    ![Mortal Kombat(1992)](/assets/images/blog-images/path-tracer/graphics-timeline/mortal-kombat.png)
    ![Alone in the Dark(1992)](/assets/images/blog-images/path-tracer/graphics-timeline/alone-in-the-dark.png)
</span>
<span class="image-row three-images">
    ![Virtua Fighter(1993)](/assets/images/blog-images/path-tracer/graphics-timeline/virtua-fighter.png)
    ![Aladdin(1993)](/assets/images/blog-images/path-tracer/graphics-timeline/aladdin.png)
    ![Doom(1993)](/assets/images/blog-images/path-tracer/graphics-timeline/doom.png)
</span>
<span class="image-row three-images">
    ![Donkey Kong Country(1994)](/assets/images/blog-images/path-tracer/graphics-timeline/donkey-kong-country.png)
    ![Panzer Dragoon(1995)](/assets/images/blog-images/path-tracer/graphics-timeline/panzer-dragoon.png)
    ![Quake(1996)](/assets/images/blog-images/path-tracer/graphics-timeline/quake.png)
</span>
<span class="image-row two-images">
    ![Super Mario 64(1996)](/assets/images/blog-images/path-tracer/graphics-timeline/super-mario-64.png)
    ![Crash Bandicoot(1996)](/assets/images/blog-images/path-tracer/graphics-timeline/crash.png)
</span>
<span class="image-row three-images">
    ![Star Fox 64(1997)](/assets/images/blog-images/path-tracer/graphics-timeline/star-fox-64.png)
    ![Gran Turismo(1997)](/assets/images/blog-images/path-tracer/graphics-timeline/gran-turismo.png)
    ![Half-Life(1998)](/assets/images/blog-images/path-tracer/graphics-timeline/half-life-one.png)
</span>
<span class="image-row two-images">
    ![Metal Gear Solid(1998)](/assets/images/blog-images/path-tracer/graphics-timeline/metal-gear-solid-2.png)
    ![Sonic Adventure(1998)](/assets/images/blog-images/path-tracer/graphics-timeline/sonic-adventure.png)
</span>
<span class="image-row two-images">
    ![Shenmue(1999)](/assets/images/blog-images/path-tracer/graphics-timeline/shenmue.png)
    ![Madden 2001(2000)](/assets/images/blog-images/path-tracer/graphics-timeline/madden.png)
</span>
<span class="image-row two-images">
![Gran Turismo 3: A-Spec(2001)](/assets/images/blog-images/path-tracer/graphics-timeline/gran-turismo-three.png)
![Grand Theft Auto III(2001)](/assets/images/blog-images/path-tracer/graphics-timeline/grand-theft-auto-three.png)
</span>
<span class="image-row three-images">
![Metal Gear Solid 2: Sons of
Liberty(2001)](/assets/images/blog-images/path-tracer/graphics-timeline/metal-gear-solid-two.png)
![Super Smash Brothers
Melee(2001)](/assets/images/blog-images/path-tracer/graphics-timeline/melee.png)
![Jet Set Radio Future(2002)](/assets/images/blog-images/path-tracer/graphics-timeline/jet-set.png)
</span>
<span class="image-row five-images">
    ![Super Mario Sunshine(2002)](/assets/images/blog-images/path-tracer/graphics-timeline/super-mario-sunshine.png)
    ![Splinter Cell(2002)](/assets/images/blog-images/path-tracer/graphics-timeline/splinter-cell.png)
    ![The legend of Zelda: The Wind
    Waker(2003)](/assets/images/blog-images/path-tracer/graphics-timeline/wind-waker.png)
    ![Viewtiful Joe(2003)](/assets/images/blog-images/path-tracer/graphics-timeline/viewtiful-joe.png)
    ![Far Cy(2004)](/assets/images/blog-images/path-tracer/graphics-timeline/far-cry.png)
</span>
<span class="image-row three-images">
    ![Half-Life 2(2004)](/assets/images/blog-images/path-tracer/graphics-timeline/half-life-two.png)
    ![F.E.A.R.(2005)](/assets/images/blog-images/path-tracer/graphics-timeline/fear.png)
    ![Call of Duty 2(2005)](/assets/images/blog-images/path-tracer/graphics-timeline/call-of-duty-two.png)
</span>
<span class="image-row two-images">
    ![Rockstar Games Presents Table
    Tennis(2006)](/assets/images/blog-images/path-tracer/graphics-timeline/table-tennis.png)
    ![Dead Rising(2006)](/assets/images/blog-images/path-tracer/graphics-timeline/dead-rising.png)
</span>
<span class="image-row">
    ![Crysis(2007)](/assets/images/blog-images/path-tracer/graphics-timeline/crysis.png)
    </span>
    <span class="image-row">
    ![Heavenly Sword(2007)](/assets/images/blog-images/path-tracer/graphics-timeline/heavenly-sword.png)
    </span>
<span class="image-row two-images">
    ![Halo 3(2007)](/assets/images/blog-images/path-tracer/graphics-timeline/halo-three.png)
    ![Team Fortress 2(2007)](/assets/images/blog-images/path-tracer/graphics-timeline/team-fortress-two.png)
</span>
    <span class="image-row two-images">
    ![Grand Theft Auto 4(2008)](/assets/images/blog-images/path-tracer/graphics-timeline/grand-theft-auto-four.png)
    ![Mirror's Edge(2008)](/assets/images/blog-images/path-tracer/graphics-timeline/mirrors-edge.png)
</span>
<span class="image-row">
![Flower(2009)](/assets/images/blog-images/path-tracer/graphics-timeline/flower.png)
</span>
<span class="image-row three-images">
    ![Uncharted 2: Among
    Thieves(2009)](/assets/images/blog-images/path-tracer/graphics-timeline/uncharted-two.png)
    ![God of War III(2010)](/assets/images/blog-images/path-tracer/graphics-timeline/god-of-war-three.png)
    ![Gran Turismo 5(2010)](/assets/images/blog-images/path-tracer/graphics-timeline/gran-turismo-five.png)
</span>
<span class="image-row two-images">![Red Dead
    Redemption(2010)](/assets/images/blog-images/path-tracer/graphics-timeline/red-dead-redemption.png)
    ![Witcher 2: Assassin of
    Kings(2011)](/assets/images/blog-images/path-tracer/graphics-timeline/witcher-two.png)
</span>
<span class="image-row three-images">
    ![Uncharted 3: Drake's
    Deception(2011)](/assets/images/blog-images/path-tracer/graphics-timeline/uncharted-three.png)
    ![Rage(2011)](/assets/images/blog-images/path-tracer/graphics-timeline/rage.png)
    ![Journey(2012)](/assets/images/blog-images/path-tracer/graphics-timeline/journey.png)
</span>
<span class="image-row three-images">
    ![Max Payne 3(2012)](/assets/images/blog-images/path-tracer/graphics-timeline/max-payne-three.png)
    ![Killzone: Shadow Fall(2013)](/assets/images/blog-images/path-tracer/graphics-timeline/killzone-shadow-fall.png)
    ![Ryse: Son of Rome(2013)](/assets/images/blog-images/path-tracer/graphics-timeline/ryse.png)
</span>
<span class="image-row two-images">
    ![Sunset Overdrive(2014)](/assets/images/blog-images/path-tracer/graphics-timeline/sunset-overdrive.png)
    ![Far Cry 4(2014)](/assets/images/blog-images/path-tracer/graphics-timeline/far-cry-four.png)
</span>
<span class="image-row">
    ![The Order: 1886(2015)](/assets/images/blog-images/path-tracer/graphics-timeline/the-order.png)
</span>
<span class="image-row two-images">
    ![Star Wars: Battlefront(2015)](/assets/images/blog-images/path-tracer/graphics-timeline/star-wars-battlefront.png)
    ![Firewatch(2016)](/assets/images/blog-images/path-tracer/graphics-timeline/firewatch.png)
</span>
<span class="image-row two-images">
    ![Uncharted 4: A Thief's End(2016)](/assets/images/blog-images/path-tracer/graphics-timeline/uncharted-four.png)
    ![Resident Evil 7(2017)](/assets/images/blog-images/path-tracer/graphics-timeline/resident-evil-seven.png)
</span>
<span class="image-row two-images">
    ![Horizon: Zero Dawn(2017)](/assets/images/blog-images/path-tracer/graphics-timeline/horizon-zero-dawn.png)
    ![Hellblade: Senua's Sacrifice(2017)](/assets/images/blog-images/path-tracer/graphics-timeline/hellblade.png)
</span>
<span class="image-row">
    ![Shadow of the Colossus(2018)](/assets/images/blog-images/path-tracer/graphics-timeline/shadow-of-the-colossus.png)
    </span>
<span class="image-row two-images">
    ![God of War(2018)](/assets/images/blog-images/path-tracer/graphics-timeline/god-of-war.png)
    ![Red Dead Redemption 2(2018)](/assets/images/blog-images/path-tracer/graphics-timeline/red-dead-two.png)
</span>
<span class="image-row two-images">
    ![Ace Combat 7: Skies Unknown(2019)](/assets/images/blog-images/path-tracer/graphics-timeline/ace-combat.png)
    ![Control(2019)](/assets/images/blog-images/path-tracer/graphics-timeline/control.png)
</span>
<span class="image-row two-images">
    ![Call of Duty: Modern Warfare(2019)](/assets/images/blog-images/path-tracer/graphics-timeline/call-of-duty-modern-warfare.png)
    ![Death Stranding(2019)](/assets/images/blog-images/path-tracer/graphics-timeline/death-stranding.png)
</span>

---

## <a id="why-explore-ray-tracing"></a>Why Explore Ray Tracing?
To put it succinctly, I chose to learn more about ray tracing for the following reasons:

  - **Graphics are neat.**

  - **Ray tracing is *very* hot right now.**
    * Despite having been first described algorithmically by [Arthur Appel in 1968](http://graphics.stanford.edu/courses/Appel.pdf), ray tracing has only recently made its way to the mainstream (like the Nvidia 20 Series (2018), the first in the industry to implement realtime hardware ray tracing in a consumer product.
    
  - **Ray tracing will likely play a huge role in rendering for years to come.** 
    * Ray tracing is applicable in more fields than just CGI, like optical design and acoustic modeling.

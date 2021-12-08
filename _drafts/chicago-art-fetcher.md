---
title: "Something to Stare At:"
subtitle: "A Highly Configurable Art Fetcher"
use-math: true
use-raw-images: false
layout: post
author: Evan
header-image: /assets\images\blog-images\art-fetcher\the-herring-net-1885.jpg
header-image-alt: Winslow Homer. The Herring Net, 1885. The Art Institute of Chicago.
header-image-title: 
tags: python web
---

<a id="continue-reading-point"></a>
I've had the [same desktop wallpaper](/assets\images\blog-images\art-fetcher\old-desktop-wallpaper.png) for almost ten years. I'd like to change it up. I'd also like to feel like an intellectual. Luckily, the [Art Institute of Chicago](https://www.artic.edu/) and their [API](https://api.artic.edu/docs/) can help me out.

<!--end-excerpt-->

---
## Contents

<ul class="table-of-contents">
    <li><a href="#the-idea">The Idea</a></li>
    <li><a href="#the-gui">The GUI</a></li>
        <ul>
            <li><a href="#creating-a-window">Creating a Window</a></li>
            <li><a href="#creating-a-frame-for-our-window">Creating a Frame for Our Window</a></li>
            <li><a href="#creating-frames-for-our-main-frame">Creating Frames for Our Main Frame</a></li>
        </ul>
        <!-- <ul>
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
        </ul> -->


</ul>

---

## <a id="the-idea"></a>The Idea

My plan is to create a simple python3 GUI for automatically downloading and managing images in a folder to be used by Windows' slideshow feature. I'd like to allow the user to perform robust queries with parameters such as:

- time period
- type of art
- predominant color
- popularity
- medium

Additionally, I'll allow the user to control:

- how many images should be in the folder at any time
- how frequently to check for updates
- whatever else feels right

---

## <a id="the-gui"></a>The GUI

I figure the GUI is as a good a place as any to start. (`tkinter`)[https://docs.python.org/3/library/tkinter.html] is the sole framework that's built in to the standard Python library, so that's what we'll be using here. I have used tkinter before (for my mostly-abandoned ['Sausage Solver'](https://github.com/eldun/SausageSolver) project), but it has been a while, so we'll get back up to speed together. If you need a more in-depth run-through, check out [tkdocs.com](https://tkdocs.com/tutorial/firstexample.html). Here's my mockup for the GUI:

<a id="mockup"></a>
<span class="captioned-image half-sized-image">
![My first draft for the art fetcher](/assets\images\blog-images\art-fetcher\mockup.png)
The general idea of the GUI
</span>
<!-- <span class="captioned-image">
![sausage-solver](/assets\images\blog-images\art-fetcher\sausage-solver.png)
My quarter-baked solver GUI from a couple months ago
</span> -->



---

## <a id="creating-a-window"></a>Creating a Window

I'll be running files as scripts, as opposed to interactively (through the interpreter).

`view.py`:
<pre><code class="language-python">
import tkinter as tk    # Standard binding to tk
import tkinter.ttk as ttk    # Binding to ttk submodule for new/prettier themed widgets

# Create window
window = tk.Tk()
window.title("ArticArtFetcher")
window.mainloop()
</code></pre>

<span class="captioned-image">
![Our GUI Window](/assets\images\blog-images\art-fetcher\basic-gui-window.png)
Our new GUI window
</span>

---

## <a id="creating-a-frame-for-our-window"></a>Creating a Frame for Our Window
Our GUI will be visually and logically separated into 'Frames'. Now that we have a window, we can add a 'main frame' to contain the rest of our frames. Why, you ask, do we need a frame for our frames if we already have a window? I had the same question; [tkdocs](https://tkdocs.com/tutorial/firstexample.html) addresses it:

> We could just put the other widgets in our interface directly into the main application window without the intervening content frame. That's what you'll see in older Tk programs.
>
>However, the main window isn't itself part of the newer "themed" widgets. Its background color doesn't match the themed widgets we will put inside it. Using a "themed" frame widget to hold the content ensures that the background is correct.
>
> ![Placing a themed frame inside a window](/assets\images\blog-images\art-fetcher\why-use-main-frame.png)

<pre><code class="language-diff-python diff-highlight">
import tkinter as tk    # Standard binding to tk
import tkinter.ttk as ttk   # Binding to ttk submodule for new/prettier themed widgets

# Create window 
window = tk.Tk()
window.title("ArticArtFetcher")

+ mainframe = ttk.Frame(master=window)
+ mainframe.grid(column=0, row=0, ipadx=200, ipady=200, sticky=(tk.N, tk.E, tk.S, tk.W))
+ window.columnconfigure(index=0, weight=1)
+ window.rowconfigure(index=0, weight=1)

window.mainloop()
</code></pre>

I added the padding just so the window would launch at 200x200. Other than that, the outward-facing result is identical:
<span class="half-sized-image">
![Our GUI Window (with Frame)](/assets\images\blog-images\art-fetcher\basic-gui-window-with-frame.png)
</span>

---

## <a id="creating-frames-for-our-main-frame"></a>Creating Frames for Our Main Frame
I'd like to divide our rudimentary GUI as illustrated in my <a href="#mockup">mockup</a>. We can accomplish that using frames.



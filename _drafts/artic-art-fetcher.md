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
            <li><a href="#setting-up-frames-within-our-main-frame">Setting Up Frames Within Our Main Frame</a></li>
            <li><a href="#handling-resize">Handling Resize</a></li>
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
+ mainframe.grid(column=0, row=0, ipadx=200, ipady=200, sticky=(tk.NSEW))
+ window.columnconfigure(index=0, weight=1)
+ window.rowconfigure(index=0, weight=1)

window.mainloop()
</code></pre>

I added the padding just so the window would launch at 200x200. Other than that, the outward-facing result is identical:
<span class="half-sized-image">
![Our GUI Window (with Frame)](/assets\images\blog-images\art-fetcher\basic-gui-window-with-frame.png)
</span>

---

## <a id="setting-up-frames-within-our-main-frame"></a>Setting Up Frames Within Our Main Frame
I'd like to divide our rudimentary GUI as illustrated in my <a href="#mockup">mockup</a>. We can accomplish that using frames. Keep in mind: 
> The size of a frame is determined by the size and layout of any widgets within it. In turn, this is controlled by the geometry manager that manages the contents of the frame itself. 

[- tkdocs](https://tkdocs.com/tutorial/widgets.html#frame)

The [grid geometry manager](https://tkdocs.com/tutorial/grid.html) will be our main tool for creating layouts. All we really have to do is plop in some grid coordinates and tell each frame where to anchor itself with the `sticky` attribute:


`view.py`
<pre><code class="language-diff-python diff-highlight">
import tkinter as tk    # Standard binding to tk
import tkinter.ttk as ttk   # Binding to ttk submodule for new/prettier themed widgets

# Create window 
window = tk.Tk()
window.title("ArticArtFetcher")

mainframe = ttk.Frame(master=window)
mainframe.grid(column=0, row=0, sticky=(tk.NSEW))
window.columnconfigure(index=0, weight=1)
window.rowconfigure(index=0, weight=1)


# Set up Frames
+ file_management_frame = ttk.Frame(master=mainframe, borderwidth=5, relief=tk.RIDGE)
+ file_management_frame.grid(column=0, row=0, sticky=(tk.NSEW))

+ artwork_criteria_frame = ttk.Frame(master=mainframe, borderwidth=5, relief=tk.RIDGE)
+ artwork_criteria_frame.grid(column=1, row=0, sticky=(tk.NE))

+ log_frame = ttk.Frame(master=mainframe, borderwidth=5, relief=tk.RIDGE)
+ log_frame.grid(column=0, row=1, sticky=(tk.NSEW))

+ button_frame = ttk.Frame(master=mainframe)
+ button_frame.grid(column=1, row=1, sticky=(tk.SE))



# Populate frames with labels
+ ttk.Label(master=file_management_frame, text="File Management").grid()
+ ttk.Label(master=artwork_criteria_frame, text="Artwork Criteria").grid()
+ ttk.Label(master=log_frame, text="Log").grid()
+ ttk.Button(master=button_frame, text="Fetch Art").grid()



window.mainloop()
</code></pre>

The result:

<span class="captioned-image">
![Basic GUI with grid layout](/assets\images\blog-images\art-fetcher\basic-gui-window-gridded.png)
Getting closer!
</span>

---

## <a id="handling-resize"></a>Handling Resize

At this point, resizing the GUI is unsightly:

<span class="captioned-image">
![Resized GUI](/assets\images\blog-images\art-fetcher\basic-gui-window-bad-resize.png)
Gross
</span>

Again from [tkdocs](https://tkdocs.com/tutorial/grid.html#resize):

> It looks like sticky may tell Tk *how* to react if the cell's row or column does resize but doesn't actually say that the row or columns *should* resize if any extra room becomes available.
>
Every column and row in the grid has a weight option associated with it. This tells grid how much the column or row should grow if there is extra room in the master to fill. By default, the weight of each column or row is 0, meaning it won't expand to fill any extra space.
>
For the user interface to resize, we'll need to specify a positive weight to the columns and rows that we'd like to expand. You must provide weights for at least one column and one row. This is done using the `columnconfigure` and `rowconfigure` methods of grid. This weight is relative. If two columns have the same weight, they'll expand at the same rate. In our example, we'll give the three leftmost columns (holding the checkboxes) weights of 3 and the two rightmost columns weights of 1. For every one pixel the right columns grow, the left columns will grow by three pixels. So as the window grows larger, most of the extra space will go to the left side.
>
![Column weight example](/assets\images\blog-images\art-fetcher\column-weight-example.png)

For posterity - `columnconfigure` and `rowconfigure` also take a `minsize` grid option.

By adding a couple config lines, we get a resizable GUI that is looking ever closer to the mockup:

`view.py`:
<pre><code class="language-diff-python diff-highlight">
import tkinter as tk
from tkinter.constants import ANCHOR    # Standard binding to tk
import tkinter.ttk as ttk   # Binding to ttk submodule for new/prettier themed widgets

# Create window 
window = tk.Tk()
window.title("ArticArtFetcher")

# Create Main Content Frame
mainframe = ttk.Frame(master=window)
mainframe.grid(column=0, row=0, sticky=(tk.NSEW))

# Handle resize proportions
+ mainframe.columnconfigure(index=0, weight=1)
+ mainframe.columnconfigure(index=1, weight=1)
+ mainframe.rowconfigure(index=0, weight=3)
+ mainframe.rowconfigure(index=1, weight=1)

window.columnconfigure(index=0, weight=1)
window.rowconfigure(index=0, weight=1)


# Set up Frames
file_management_frame = ttk.Frame(master=mainframe, borderwidth=5, relief=tk.RIDGE)
file_management_frame.grid(column=0, row=0, sticky=(tk.NSEW))

artwork_criteria_frame = ttk.Frame(master=mainframe, borderwidth=5, relief=tk.RIDGE)
artwork_criteria_frame.grid(column=1, row=0, sticky=(tk.NSEW))

log_frame = ttk.Frame(master=mainframe, borderwidth=5, relief=tk.RIDGE)
log_frame.grid(column=0, row=1, sticky=(tk.NSEW))

button_frame = ttk.Frame(master=mainframe)
button_frame.grid(column=1, row=1)



# Populate frames with labels
ttk.Label(master=file_management_frame, text="File Management").grid()
ttk.Label(master=artwork_criteria_frame, text="Artwork Criteria").grid()
ttk.Label(master=log_frame, text="Log").grid()
ttk.Button(master=button_frame, text="Fetch Art").grid()



window.mainloop()

</code></pre>

<span class="row">
![Poorly Resized GUI](/assets\images\blog-images\art-fetcher\basic-gui-window-bad-resize.png)
![Appropriately Resized GUI](/assets\images\blog-images\art-fetcher\basic-gui-window-good-resize.png)
</span>







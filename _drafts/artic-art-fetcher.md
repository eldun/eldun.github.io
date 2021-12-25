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
            <li><a href="#the-big-picture">The Big Picture</a></li>
                <ul>
                    <li><a href="#creating-a-window">Creating a Window</a></li>
                    <li><a href="#creating-a-frame-for-our-window">Creating a Frame for Our Window</a></li>
                    <li><a href="#setting-up-frames-within-our-main-frame">Setting Up Frames Within Our Main Frame</a></li>
                    <li><a href="#handling-resize">Handling Resize</a></li>
                    <li><a href="#changing-frames-to-labelframes">Changing Frames to Labelframes</a></li>
                </ul>
            </li>
            <li><a href="#the-file-management-section">The File Management Section</a></li>
            <li><a href="#the-artwork-criteria-section">The File Management Section</a></li>
            </li>
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

## <a id="the-big picture"></a>The Big Picture


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
I'm going to use the [template](https://stackoverflow.com/a/17470842) that [Bryan Oakley](https://stackoverflow.com/users/7432/bryan-oakley) uses for his tkinter projects. If you're wondering who Bryan is, have a look at his StackOverflow profile. He's the top answerer to most tkinter questions I've looked up. It's his thing.

Originally, I coded this GUI in a more procedural manner (like in the [tkdocs eqample](https://tkdocs.com/tutorial/firstexample.html)), but it started getting messy.

`fetcher.py`:
<pre><code class="language-python">
import tkinter as tk    # Standard binding to tk
import tkinter.ttk as ttk    # Binding to ttk submodule for new/prettier themed widgets

class MainApplication(ttk.Frame):
    def __init__(self, parent, *args, **kwargs):
        ttk.Frame.__init__(self, parent, *args, **kwargs)
        self.parent = parent

        &lt;create the rest of your GUI here>

if __name__ == "__main__":
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
import tkinter.ttk as ttk    # Binding to ttk submodule for new/prettier themed widgets

class MainApplication(ttk.Frame):
    def __init__(self, parent, *args, **kwargs):
        super().__init__(self, parent, *args, **kwargs)
        self.parent = parent


if __name__ == "__main__":
    # Create window
    window = tk.Tk()
    window.title("ArticArtFetcher")
+   window.columnconfigure(index=0, weight=1)
+   window.rowconfigure(index=0, weight=1)
+   window.minsize(200, 200)
+
+   # Create frame for window
+   MainApplication(parent=window).grid(column=0, row=0, sticky=(tk.NSEW))

    window.mainloop()
</code></pre>

The outward-facing result is identical:
<span class="half-sized-image">
![Our GUI Window (with Frame)](/assets\images\blog-images\art-fetcher\basic-gui-window-with-frame.png)
</span>

---

## <a id="setting-up-frames-within-our-main-frame"></a>Setting Up Frames Within Our Main Frame
I'd like to divide our rudimentary GUI as illustrated in my <a href="#mockup">mockup</a>. We can accomplish that using [LabelFrames](https://tkdocs.com/tutorial/complex.html#labelframe).


The [grid geometry manager](https://tkdocs.com/tutorial/grid.html) will be our main tool for creating layouts. All we really have to do is plop in some grid coordinates and tell each widget where to anchor itself with the `sticky` attribute. Before we can do that, though, we'll have to create our new widget classes as illustrated in [Bryan Oakley's StackOverflow answer](https://stackoverflow.com/a/17470842).


`fetcher.py`:
<pre><code class="language-diff-python diff-highlight">
+class FileManagementFrame(ttk.Labelframe):
+    pass
+
+        
+class ArtworkCriteriaFrame(ttk.Labelframe):
+    pass
+
+class LogPaneFrame(ttk.Labelframe):
+    pass
+
+class FetchButtonFrame(ttk.Frame):
+    pass        
+
 class MainApplication(ttk.Frame):
     def __init__(self, parent, *args, **kwargs):
         super().__init__(parent, *args, **kwargs)
      
         self.parent = parent
       

+        self.file_management_frame = FileManagementFrame(self, text="File Management", borderwidth=5, relief=tk.RIDGE)
+        self.artwork_criteria_frame = ArtworkCriteriaFrame(self,  text="Artwork Criteria", borderwidth=5, relief=tk.RIDGE)
+        self.log_panel_frame = LogPaneFrame(self,  text="Log", borderwidth=5, relief=tk.RIDGE)
+        self.fetch_button_frame = FetchButtonFrame(self, borderwidth=5, relief=tk.RIDGE)
+
+        self.file_management_frame.grid(column=0, row=0, sticky=(NSEW), padx=10, pady=10)
+        self.artwork_criteria_frame.grid(column=1, row=0, sticky=(NSEW), padx=10, pady=10)
+        self.log_panel_frame.grid(column=0, row=1, sticky=(NSEW), padx=10, pady=10)
+        self.fetch_button_frame.grid(column=1, row=2, padx=10, pady=5, sticky=NSEW)


if __name__ == "__main__":
    # Create window
    window = tk.Tk()
    window.title("ArticArtFetcher")
    window.columnconfigure(index=0, weight=1)
    window.rowconfigure(index=0, weight=1)
    window.minsize(200, 200)


    # Create frame for window
    MainApplication(parent=window).grid(column=0, row=0 sticky=(tk.NSEW))

    window.mainloop()
</code></pre>

When you run this code, you'll end up with an empty window. What's wrong? For one, our Labelframes have nothing in them. Secondly, the rows and columns aren't configured to resize (we'll address resizing in the next section).

> The size of a frame is determined by the size and layout of any widgets within it. In turn, this is controlled by the geometry manager that manages the contents of the frame itself.

[-tkdocs](https://tkdocs.com/tutorial/widgets.html#frame)

Let's add some placeholder labels, just to see how things look.

`fetcher.py`:
<pre><code class="language-diff-python diff-highlight">
class FileManagementFrame(ttk.Labelframe):
-   pass
+   def __init__(self, parent, *args, **kwargs):
+       super().__init__(parent, *args, **kwargs)
+       tk.Label(master=self, text="file management").grid()
        
class ArtworkCriteriaFrame(ttk.Labelframe):
-   pass
+   def __init__(self, parent, *args, **kwargs):
+       super().__init__(parent, *args, **kwargs)    
+       tk.Label(master=self, text="artwork").grid()

class LogPaneFrame(ttk.Labelframe):
-   pass
+   def __init__(self, parent, *args, **kwargs):
+       super().__init__(parent, *args, **kwargs)   
+       tk.Label(master=self, text="log").grid()
 
class FetchButtonFrame(ttk.Frame):   
-   pass
+   def __init__(self, parent, *args, **kwargs):
+       super().__init__(parent, *args, **kwargs)    
+       tk.Label(master=self, text="fetch art").grid()
</code></pre>

<span class="row">
    <span class="captioned-image">
        ![Empty Labelframes](/assets\images\blog-images\art-fetcher\basic-gui-window-with-empty-labelframes.png)
Before
    </span>
    <span class="captioned-image">
        ![Labelframes with placeholder widgets](/assets\images\blog-images\art-fetcher\basic-gui-with-filled-labelframes.png)
After
    </span>
</span>

---

## <a id="handling-resize"></a>Handling Resize

If we try to resize our nice little window, things look bad:

<span class="row">
    <span class="captioned-image">
        ![Initial window](/assets\images\blog-images\art-fetcher\basic-gui-with-filled-labelframes.png)
Initial
    </span>
    <span class="captioned-image">
        ![Poorly Resized GUI](/assets\images\blog-images\art-fetcher\basic-gui-window-bad-resize.png)
Resized
    </span>
</span>

What's wrong here? lets turn to the [tkdocs](https://tkdocs.com/tutorial/grid.html#resize):

> It looks like sticky may tell Tk *how* to react if the cell's row or column does resize but doesn't actually say that the row or columns *should* resize if any extra room becomes available.
>
Every column and row in the grid has a weight option associated with it. This tells grid how much the column or row should grow if there is extra room in the master to fill. By default, the weight of each column or row is 0, meaning it won't expand to fill any extra space.
>
For the user interface to resize, we'll need to specify a positive weight to the columns and rows that we'd like to expand. You must provide weights for at least one column and one row. This is done using the `columnconfigure` and `rowconfigure` methods of grid. This weight is relative. If two columns have the same weight, they'll expand at the same rate. In our example, we'll give the three leftmost columns (holding the checkboxes) weights of 3 and the two rightmost columns weights of 1. For every one pixel the right columns grow, the left columns will grow by three pixels. So as the window grows larger, most of the extra space will go to the left side.
>
![Column weight example](/assets\images\blog-images\art-fetcher\column-weight-example.png)

For posterity - `columnconfigure` and `rowconfigure` also take a `minsize` grid option.

By adding a couple config lines, we get a resizable GUI that is looking ever closer to the mockup:

`fetcher.py`:
<pre><code class="language-diff-python diff-highlight">
...

if __name__ == "__main__":
    # Create window
    window = tk.Tk()
    window.title("ArticArtFetcher")
    window.columnconfigure(index=0, weight=1)
    window.rowconfigure(index=0, weight=1)
    window.minsize(200, 200)

    # Create frame for window
    main_application = MainApplication(parent=window)
    main_application.grid(column=0, row=0, sticky=(tk.NSEW))

    # Configure resize
+   main_application.columnconfigure(index=0, weight=1)
+   main_application.columnconfigure(index=1, weight=1)
+   main_application.rowconfigure(index=0, weight=1)
+   main_application.rowconfigure(index=1, weight=1)
+   main_application.rowconfigure(index=2, weight=1)

    window.mainloop()

</code></pre>


In fact, we don't even need placeholder labels now that the geometry manager has been configured:

<span class="row">
    <span class="captioned-image">
        ![Initial window](/assets\images\blog-images\art-fetcher\basic-gui-with-filled-labelframes.png)
Initial
    </span>
    <span class="captioned-image">
        ![Poorly Resized GUI](/assets\images\blog-images\art-fetcher\basic-gui-window-bad-resize.png)
Resized without weight configuration
    </span>
        <span class="captioned-image">
        ![Properly Resized GUI](/assets\images\blog-images\art-fetcher\basic-gui-window-good-resize.png)
Resized with weight configuration
    </span> 
    <span class="captioned-image">
        ![Properly Resized GUI](/assets\images\blog-images\art-fetcher\basic-gui-window-good-resize-labels-removed.png)
Resized with placeholder labels removed
    </span>
</span>


---



## <a id="the-file-management-section"></a>The File Management Section

There are a few things I know I want the user to be able to control in regards to the filesystem. I'm sure I'll think of more features once the program is actually usable. Here's my list (for now):

- Directory selector
- Maximum picture count
- Maximum folder size
- Auto-delete
- Download frequency
- Description (either as .txt file on desktop or by finding a way to incorporate text into image)

Here's the code to set up a dummy version of what I want within the `FileManagementFrame` class:


`fetcher.py`:
<pre><code class="language-diff-python diff-highlight">

import tkinter as tk    # Standard binding to tk
import tkinter.ttk as ttk    # Binding to ttk submodule for new/prettier themed widgets
from tkinter.constants import NSEW, NE, NW, SE, SW, N, S, E, W   # Standard binding to tk
+ import tkinter.filedialog as filedialog


class FileManagementFrame(ttk.Labelframe):
    def __init__(self, parent, *args, **kwargs):
        super().__init__(parent, *args, **kwargs)

+        # Populate file management section
+
+        # Directory selection
+        output_directory="Placeholder Directory"
+        ttk.Label(self, text=f"Artwork Directory: {output_directory}").grid(column=0, row=0, sticky=W, padx=5, pady=5)
+        ttk.Button(self, text="Choose Directory", command=filedialog.askdirectory).grid(column=1, row=0, padx=5, pady=5, sticky=E)
+
+        # 'Max size' options
+        ttk.Label(self, text="Max Picture Count").grid(column=0, row=1, sticky=W, padx=5, pady=5)
+        ttk.Entry(self).grid(column=1, row=1, padx=5, pady=5, sticky=E)
+
+        ttk.Label(self, text="Max Folder Size").grid(column=0, row=2, sticky=W, padx=5, pady=5)
+        ttk.Entry(self).grid(column=1, row=2, padx=5, pady=5, sticky=tk.W)
+        folder_size_units_combobox = ttk.Combobox(self)
+        folder_size_units_combobox['values'] = ('MB', 'GB', 'TB')
+        folder_size_units_combobox.state(['readonly'])
+        folder_size_units_combobox.grid(column=2, row=2, padx=5, pady=5, sticky=W)
+
+        # Auto Delete option
+        ttk.Checkbutton(self, text="Auto-delete old files").grid(column=0, row=3, padx=5, pady=5, sticky=W)
+
+        # Update frequency option
+        ttk.Label(self, text="Download new files every: ").grid(column=0, row=4, sticky=W, padx=5, pady=5)
+        ttk.Entry(self).grid(column=1, row=4, padx=5, pady=5, sticky=tk.W)
+        art_check_frequency_combobox = ttk.Combobox(self)
+        art_check_frequency_combobox['values'] = ('Hours', 'Days', 'Weeks', 'Months')
+        art_check_frequency_combobox.state(['readonly'])
+        art_check_frequency_combobox.grid(column=2, row=4, padx=5, pady=5, sticky=W)
+
+        # Description file option
+        ttk.Checkbutton(self, text="Create artwork description file on desktop").grid(column=0, row=5, sticky=W, padx=5, pady=5)
+
+
+
+
+
+
+
+        # Configure resizing for file management columns
+        self.columnconfigure(index=0, weight=0)
+        self.columnconfigure(index=1, weight=0)
+
+        for row in range(self.grid_size()[1]):
+            self.rowconfigure(row, weight=1, minsize=30)

...

</code></pre>

<span class="half-sized-image">
![Dummy file management section](\assets\images\blog-images\art-fetcher\dummy-file-management-section.png)

As will be the case with the other sections, we'll hook up everything with callbacks further down the line.




## <a id="the-artwork-criteria-section"></a>The Artwork Criteria Section

Here's a short list of some criteria that may be worth filtering by:

- time period
- artist
- type of art (e.g. painting, sculpture, book)
- predominant color
- popularity
- style (e.g. impressionist, abstract)
- theme

More may come later. I think it'd also be neat to choose images based on the current weather and time - but that may belong in the file management section, once they're already downloaded. I'm getting ahead of myself - let's populate our art section in our GUI with dummy widgets!



`fetcher.py`:
<pre><code class="language-diff-python diff-highlight">


</code></pre>





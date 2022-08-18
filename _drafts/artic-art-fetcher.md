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
        <li><a href="#creating-the-gui-sections">Creating the GUI Sections</a></li>
        <ul>
            <li><a href="#the-file-management-section">The File Management Section</a></li>
            <li><a href="#the-artwork-criteria-section">The Artwork Criteria Section</a></li>
            <li><a href="#the-logging-pane">The Logging Pane</a></li>
            <li><a href="#the-fetch-button">The Fectch Button</a></li>
        </ul>
    <li><a href="#creating-the-model">Creating the Model</a></li>
        <ul>
            <li><a href="#hooking-up-the-file-management-section">The File Management Section</a></li>
        </ul>
        <li><a href="#creating-the-backend">Creating the Backend</a></li>
        <ul>
            <li><a href="#forming a connection">The File Management Section</a></li>
        </ul>

    </ul>

</ul>

---

## <a id="the-idea"></a>The Idea

My plan is to create a simple python GUI for automatically downloading and managing images in a folder to be used by Windows' slideshow feature. I'd like to allow the user to perform robust queries with parameters such as:

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

Here's the code to set up a dummy version of what I want within the `FileManagementFrame` class. The widgets we're using are assigned to a variable so that we can later retrieve their values in `controller.py`.


`fetcher.py`:
<pre><code class="language-diff-python diff-highlight">

import tkinter as tk    # Standard binding to tk
import tkinter.ttk as ttk    # Binding to ttk submodule for new/prettier themed widgets
from tkinter.constants import NSEW, NE, NW, SE, SW, N, S, E, W   # Standard binding to tk
import tkinter.filedialog as filedialog


+ class FileManagementFrame(ttk.Labelframe):
+     def __init__(self, parent, *args, **kwargs):
+         super().__init__(parent, *args, **kwargs)
+ 
+         # Populate file management section

         # Directory selection
        self.output_directory = tk.StringVar()
        self.output_directory.set("No Directory Selected")
        tk.Label(self, text="Artwork Directory: ").grid(column=0, row=0, sticky=W)
        tk.Label(self, textvariable=self.output_directory).grid(column=1, row=0, sticky=W)
        ttk.Button(self, text="Choose Directory", command=self.choose_directory).grid(column=2, row=0)


        # 'Max pic count' options
        ttk.Label(self, text="Max Picture Count:").grid(column=0, row=1, sticky=W)
        self.max_picture_count_entry = ttk.Entry(self, width=7)
        self.max_picture_count_entry.grid(column=2, row=1)


        # Max folder size
        ttk.Label(self, text="Max Folder Size:").grid(column=0, row=2, sticky=W)
        max_size_frame = ttk.Frame(self)

        self.max_folder_size_entry = ttk.Entry(max_size_frame, width=4)
        self.max_folder_size_entry.grid(column=0, row=0)

        self.folder_size_units_combobox = ttk.Combobox(max_size_frame, width=2)
        self.folder_size_units_combobox['values'] = ('MB', 'GB', 'TB')
        self.folder_size_units_combobox.state(['readonly'])
        self.folder_size_units_combobox.grid(column=1, row=0)

        max_size_frame.grid(column=2, row=2)

        # Auto Delete option
        ttk.Label(self, text="Auto-delete old files:").grid(column=0, row=3, sticky=W)
        # For whatever reason, I have to create a variable to hold the value of the checkbox instead of just getting the widget itself
        self.auto_delete_checkbutton_var = tk.BooleanVar()
        self.auto_delete_checkbutton = tk.Checkbutton(self, anchor=CENTER, variable=self.auto_delete_checkbutton_var)
        self.auto_delete_checkbutton.grid(column=2, row=3, sticky=EW)

        # Update frequency option
        ttk.Label(self, text="Download new files every:").grid(column=0, row=4, sticky=W)

        update_frequency_frame = ttk.Frame(self)
        self.update_frequency_entry = ttk.Entry(update_frequency_frame, width=3)
        self.update_frequency_entry.grid(column=0, row=0)
        self.art_check_frequency_combobox = ttk.Combobox(update_frequency_frame, width=5)
        self.art_check_frequency_combobox['values'] = ('Hours', 'Days', 'Weeks', 'Months')
        self.art_check_frequency_combobox.state(['readonly'])
        self.art_check_frequency_combobox.grid(column=1, row=0)
        update_frequency_frame.grid(column=2,row=4)

        # Description file option
        
        ttk.Label(self, text="Create artwork description file on desktop:").grid(column=0, row=5, sticky=W, columnspan=2)
        # For whatever reason, I have to create a variable to hold the value of the checkbox instead of just getting the widget itself
        self.create_description_checkbutton_var = tk.BooleanVar()
        self.create_description_checkbutton = tk.Checkbutton(self, anchor=CENTER, variable=self.create_description_checkbutton_var)
        self.create_description_checkbutton.grid(column=2, row=5, sticky=EW)

        self.columnconfigure(index=0, weight=1)
        self.columnconfigure(index=1, weight=0)
        self.columnconfigure(index=2, weight=1)

        configure_frame_row_resize(self)
        
        add_widget_padding(self)

    def choose_directory(self):
        dir = filedialog.askdirectory(mustexist=True)

        self.output_directory.set(dir)

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
...


class ArtworkCriteriaFrame(ttk.Labelframe):

    def on_choose_color(self):
            colorchooser.askcolor()

    def __init__(self, parent, *args, **kwargs):
        super().__init__(parent, *args, **kwargs)

        # Date range        
        current_row = 0
        ttk.Label(self, text="Date Range (Inclusive)").grid(column=0, row=current_row, sticky=W)
        date_range = ttk.Frame(master=self)
        self.date_start_entry = ttk.Entry(date_range, width=5)
        self.date_start_entry.grid(column=0, row=current_row)

        self.date_start_age = ttk.Combobox(date_range, width=3)
        self.date_start_age['values'] = ('BC','AD')
        self.date_start_age.current(0)
        self.date_start_age.grid(column=1, row=current_row)
        ttk.Label(date_range, text="-").grid(column=2, row=current_row)

        self.date_end_entry = ttk.Entry(date_range, width=5)
        self.date_end_entry.grid(column=3, row=current_row)
        self.date_end_age = ttk.Combobox(date_range, width=3)
        self.date_end_age['values'] = ('BC','AD')
        self.date_end_age.current(0)
        self.date_end_age.grid(column=4, row=current_row)
        date_range.grid(column=2, row=current_row)

        # Artist
        current_row += 1
        ttk.Label(self, text="Artist").grid(column=0, row=current_row, sticky=W)
        self.artist_combobox = ttk.Combobox(self, width=12)
        self.artist_combobox.grid(column=2, row=current_row)

        # Art type(e.g. painting, sculpture, etc.)
        current_row += 1
        ttk.Label(self, text="Type").grid(column=0, row=current_row, sticky=W)
        self.art_type_combobox = ttk.Combobox(self, width=12)
        self.art_type_combobox.grid(column=2, row=current_row)

        # Color
        current_row += 1        
        ttk.Label(self, text="Predominant Color").grid(column=0, row=current_row, sticky=W)
        color_frame = ttk.Frame(self)
        ttk.Button(color_frame, command=self.on_choose_color).grid(column=0, row=0, sticky=EW)
        self.choose_color_entry = ttk.Entry(color_frame, width=7)
        self.choose_color_entry.grid(column=1, row=0, sticky=E)
        color_frame.grid(column=2, row=current_row)

        # Rarity
        current_row += 1
        ttk.Label(self, text="Fetch rarely viewed art").grid(column=0, row=current_row, sticky=W)
        self.rarity_checkbutton_var = tk.BooleanVar()
        tk.Checkbutton(self, variable=self.rarity_checkbutton_var).grid(column=2, row=current_row, sticky=EW)

        # Style (e.g. impressionist, abstract, etc.)
        current_row += 1
        ttk.Label(self, text="Style").grid(column=0, row=current_row, sticky=W)
        self.style_combobox = ttk.Combobox(self, width=12)
        self.style_combobox.grid(column=2, row=current_row)



        self.columnconfigure(index=0, weight=1)
        self.columnconfigure(index=1, weight=0)
        self.columnconfigure(index=2, weight=1)


        configure_frame_row_resize(self)

        add_widget_padding(self)

...

def configure_frame_row_resize(frame):
    for row in range(frame.grid_size()[1]):
        frame.rowconfigure(row, weight=1)

def add_widget_padding(frame):
    for widget in frame.winfo_children():
        widget.grid_configure(padx=5, pady=5)
        add_widget_padding(widget)


...

if __name__ == "__main__":
    # Create window
    window = tk.Tk()
    window.title("ArticArtFetcher")
    window.columnconfigure(index=0, weight=1)
    window.rowconfigure(index=0, weight=1)
+    window.minsize(800, 800)

    # Create frame for window
    main_application = MainApplication(parent=window)
    main_application.grid(column=0, row=0, sticky=(tk.NSEW))

    # Configure resize
    main_application.columnconfigure(index=0, weight=1)
    main_application.columnconfigure(index=1, weight=1)
    main_application.rowconfigure(index=0, weight=1)
    main_application.rowconfigure(index=1, weight=1)
    main_application.rowconfigure(index=2, weight=1)



</code></pre>

There we have it! Note that I also configured the minsize of the rows and columns.



## <a id="the-logging-pane"></a>The Logging Pane
Thankfully, there's a module for basic scrolling text widget, which makes this section pretty straightforward:

`fetcher.py`:
<pre><code class="language-python">
class LogPaneFrame(ttk.Labelframe):

    def __init__(self, parent, *args, **kwargs):
        super().__init__(parent, *args, **kwargs)

        self.scrolled_text = scrolledtext.ScrolledText(master=self)
        self.scrolled_text.configure(state=tk.DISABLED, background='light gray')
        self.scrolled_text.tag_config('warning', background='black', foreground='red')
        self.scrolled_text.tag_config('success', background='black', foreground='green')

        self.scrolled_text.grid(column=0, row=0, sticky=NSEW)


        self.columnconfigure(index=0, weight=1)
        self.rowconfigure(index=0, weight=1, minsize=10)
        configure_frame_row_resize(self)

    def log_message(self, message, tag=None):
        
        self.scrolled_text.configure(state=tk.NORMAL)
        self.scrolled_text.insert(tk.END,"\n" + message + "\n", tag)
        self.scrolled_text.configure(state=tk.DISABLED)
</code></pre>

## <a id="the-fetch-button"></a>The Fetch Button

`fetcher.py`:
<pre><code class="language-python">
class FetchButtonFrame(ttk.Frame):
    def __init__(self, parent, *args, **kwargs):
        super().__init__(parent, *args, **kwargs)
        ttk.Button(self, text="Fetch").grid(column=0, row=0, sticky=NSEW)

        self.rowconfigure(0, weight=1)
        self.columnconfigure(0, weight=1)
</code></pre>

<span class="captioned-image">
![Dummy GUI](\assets\images\blog-images\art-fetcher\dummy-gui.png)
Our dummy GUI
</span>

## <a id="creating-the-model"></a>Creating the Model

As you may know, the view component of the [Model-View-Controller (MVC) design pattern](https://developer.mozilla.org/en-US/docs/Glossary/MVC) is "dumb" - it doesn't store any data - it merely represents the data stored within the model. First, let's refactor our files to more closely follow the principles of MVC.

We'll move all of our `fetcher.py` code into `view.py` except for the `__main__` section.

`view.py`:
<pre><code class="language-python diff-highlight">
import tkinter as tk    # Standard binding to tk
import tkinter.ttk as ttk    # Binding to ttk submodule for new/prettier themed widgets
from tkinter.constants import CENTER, EW, NSEW, NE, NW, SE, SW, N, S, E, W   # Standard binding to tk
import tkinter.filedialog as filedialog
import tkinter.colorchooser as colorchooser
import tkinter.scrolledtext as scrolledtext

class FileManagementFrame(ttk.Labelframe):
    ...

class ArtworkCriteriaFrame(ttk.Labelframe):

    ...
  
class LogPaneFrame(ttk.Labelframe):

    ...

class FetchButtonFrame(ttk.Frame):
    ...

class MainApplication(ttk.Frame):
    ...
</code></pre>

That leaves `fetcher.py` (with a few minor changes):
<pre><code class="language-diff-python diff-highlight">
+ import tkinter as tk
+ import view

if __name__ == "__main__":
    # Create window
    window = tk.Tk()
    window.title("ArticArtFetcher")
    window.columnconfigure(index=0, weight=1)
    window.rowconfigure(index=0, weight=1)
    window.minsize(800,400)

    # Create frame for window
+   main_application = view.MainApplication(parent=window)
    main_application.grid(column=0, row=0, sticky=(tk.NSEW))

    # Configure resize
    main_application.columnconfigure(index=0, weight=1)
    main_application.columnconfigure(index=1, weight=1)
    # Log pane should be the only row that shrinks/resizes
    main_application.rowconfigure(index=1, weight=1)


    window.mainloop()
</code></pre>

This will be our point of entry. The model, view, and (eventually) the controller will be conveniently separated from here onwards.

Now we can get to work designing our model. Create a file by the name of `model.py` in the root folder, and we'll continue on section by section.

### <a id="the-file-management-section"></a>The File Management Section
Let's take a look at our GUI and build our model accordingly.
![Dummy GUI](\assets\images\blog-images\art-fetcher\dummy-gui.png)

We'll start with some placeholders for all of our options:

`model.py`:
<pre><code class="language-python">

class Model():
    def __init__(self):
        self.file_management_model = FileManagementModel()
        self.artwork_criteria_model = ArtworkCriteriaModel()


class FileManagementModel():
    def __init__(self):
        self.directory = None
        self.max_picture_count = None
        self.max_folder_size = None
        self.max_folder_size_units = None
        self.auto_delete = None
        self.download_frequency = None
        self.download_frequency_units = None
        self.create_description = None


class ArtworkCriteriaModel():
    def __init__(self):
        self.date_start = None
        self.date_start_era = None
        self.date_end = None
        self.date_end_era = None
        self.artist = None
        self.type = None
        self.predominant_color = None
        self.fetch_rare_art = None
        self.style = None
</code></pre>

We can later turn these attributes into [properties](https://www.programiz.com/python-programming/property) to implement business logic/constraints.

We'll need a way to change these values when the user interacts with the view, which we can accomplish by using tkinter's `bind()` function - covered in the next section.

### <a id="binding-view-interactions-to-the-conntroller"></a>Binding View Interactions to the Controller

![MVC Pattern](\assets\images\blog-images\art-fetcher\model-view-controller.png)

The first order of business is allowing the view to reference the controller:

`view.py`:
<pre><code class="language-diff-python diff-highlight">
class MainApplication(ttk.Frame):
    def __init__(self, parent, *args, **kwargs):
        super().__init__(parent, *args, **kwargs)

        self.parent = parent
+       self.controller = None

        ...

+   def set_controller(self, controller):
+       self.controller = controller
</code></pre>

`controller.py`:
<pre><code class="language-diff-python diff-highlight">
class Controller():
    def __init__(self, view):
        self.view = view
</code></pre>

`fetcher.py`:
<pre><code class="language-diff-python diff-highlight">
import tkinter as tk
+ import model, view, controller

if __name__ == "__main__":
    # Create window
    window = tk.Tk()

    ...

    # Log pane should be the only row that shrinks/resizes
    main_application.rowconfigure(index=1, weight=1)

+   view = main_application
+   controller = controller.Controller()
+   view.set_controller(controller)

    window.mainloop()
</code></pre>

At this point, we can use [tkinter's `bind` function](https://docs.python.org/3/library/tkinter.html?highlight=bind#bindings-and-events) to invoke certain functions upon certain actions. Some widgets have binding as a keyword parameter(called `command`), like `Button`. However, we can just use `bind()` on whichever widget we desire.

I believe in our situation, it makes the most sense to simply send all the values from the view to the model when the user clicks fetch (We'll cover validation later). Let's bind the fetch button to a controller function:

`controller.py`:
<pre><code class="language-diff-python diff-highlight">
class Controller():
    def __init__(self, view):
        self.view = view

+    def on_fetch_button_clicked(self, event):
+        print("fetch clicked")

</code></pre>

`view.py`:
<pre><code class="language-diff-python diff-highlight">
...

class FetchButtonFrame(ttk.Frame):
    def __init__(self, parent, *args, **kwargs):
        super().__init__(parent, *args, **kwargs)
-        tk.Button(self, text="Fetch", bg='light green').grid(column=0, row=0, sticky=NSEW)
+        self.fetch_button = tk.Button(self, text="Fetch", bg='light green')
+        self.fetch_button.grid(column=0, row=0, sticky=NSEW)

        self.rowconfigure(0, weight=1)
        self.columnconfigure(0, weight=1)

...

class MainApplication(ttk.Frame):
    def __init__(self, parent, *args, **kwargs):
        ...

+    def configure_bindings(self):
+        self.fetch_button_frame.fetch_button.bind(sequence="&ltButtonPress&gt", func=self.controller.on_fetch_button_clicked)
</code></pre>

Note that we had to split up the instantiation and `grid()`ing of `fetch_button`. This is because grid always returns `None`, which is no good because we're going to want to reference the button in `configure_bindings`.

If you run the program and click fetch, you'll see "fetch clicked" in the console.

### <a id="performing-preliminary-validation-in-the-view"></a>Performing Preliminary Validation in the View

It's a good idea - before sending our user's input to the controller - to do some simple validation in the view - such as only allowing integers in the "Max Picture Count" field. Let's follow the [doc](https://anzeljg.github.io/rin2/book2/2405/docs/tkinter/entry-validation.html).

(Sculpting the data for the API will take place in the controller, and ensuring that the data "makes sense"(business logic) will take place in the model.)

> 1. Write a callback function that checks the text in the Entry and returns `True` if the text is valid, or `False` if not. If the callback returns `False`, the user's attempt to edit the text will be refused, and the text will be unchanged.

Let's create a function for validating int-only entries. We'll just make it a [module function](https://stackoverflow.com/a/11788267), like `configure_frame_row_resize` and `add_widget_padding`, since it'll be used across frames.


`view.py`:
<pre><code class="language-diff-python diff-highlight">

def on_int_entry_edited(text):
    if str.isdigit(text) or text == "":
        return True
    else:
        return False
</code></pre>

> 2. Register the callback function. In this step, you will produce a Tcl wrapper around a Python function.
>
> Suppose your callback function is a function named `isOkay`. To register this function, use the universal widget method `.register(isOkay)`. This method returns a character string that Tkinter can use to call your function.

`view.py`:
<pre><code class="language-diff-python diff-highlight">

class FileManagementFrame(ttk.Labelframe):
    def __init__(self, parent, *args, **kwargs):

        ...

        # 'Max pic count' options
        ttk.Label(self, text="Max Picture Count:").grid(column=0, row=1, sticky=W)
        self.max_picture_count_entry = ttk.Entry(self, width=7)
        self.max_picture_count_entry.grid(column=2, row=1)

+       int_validaiton_command = self.max_picture_count_entry.register(on_int_entry_edited)

</code></pre>

> 3. When you call the Entry constructor, use the `validatecommand` option in the Entry constructor to specify your callback, and use the `validate` option to specify when the callback will be called to validate the text in the callback.

See [here](https://anzeljg.github.io/rin2/book2/2405/docs/tkinter/entry-validation.html) for a list of options. We'll just be using 'all'.

`view.py`:
<pre><code class="language-diff-python diff-highlight">

class FileManagementFrame(ttk.Labelframe):
    def __init__(self, parent, *args, **kwargs):

        ...

        # 'Max pic count' options
        ttk.Label(self, text="Max Picture Count:").grid(column=0, row=1, sticky=W)
        self.max_picture_count_entry = ttk.Entry(self, width=7)
        self.max_picture_count_entry.grid(column=2, row=1)

        self.max_picture_count_entry.register(on_int_entry_edited)
        self.max_picture_count_entry.config(validate='all', validatecommand=(int_validaiton_command, '%P'))

</code></pre>

Note the `'%P'` in our `validatecommand` argument. This is a substituiton code describing the value that the text will have if the change is allowed. You can find all the substituiton codes and how to use them [here](https://anzeljg.github.io/rin2/book2/2405/docs/tkinter/entry-validation.html).

You can now use this validation method with other int-only fields, like "Max Folder Size":

`view.py`:
<pre><code class="language-diff-python diff-highlight">
    ...

    # Max folder size
    ttk.Label(self, text="Max Folder Size:").grid(column=0, row=2, sticky=W)
    max_size_frame = ttk.Frame(self)

    self.max_folder_size_entry = ttk.Entry(max_size_frame, width=4)
    self.max_folder_size_entry.grid(column=0, row=0)
+   self.max_folder_size_entry.config(validate='all', validatecommand=(int_validaiton_command, '%P'))

...
</code></pre>


### <a id="getting-view-data-to-the-model"></a>Getting View Data to the Model

Let's start by passing the instance of our model to our controller:

`fetcher.py`:
<pre><code class="language-diff-python diff-highlight">

...

+    model = model.Model()
    view = main_application
+    controller = controller.Controller(model, view)

    view.set_controller(controller)
    view.configure_bindings()

    window.mainloop()
</code></pre>

And then setting our model attributes to the values entered in the view:

`controller.py`:
<pre><code class="language-diff-python diff-highlight">

class Controller():
    def __init__(self, model, view):
+        self.model = model
        self.view = view

    def on_fetch_button_clicked(self, event):

+        self.update_file_management_model()
+        self.update_file_artwork_criteria_model()
        

    def update_file_management_model(self):
        model = self.model.file_management_model
        view = self.view.file_management_frame


        try:

            model.output_directory = view.output_directory
            model.max_picture_count = view.max_picture_count_entry.get()
            model.max_folder_size = view.max_folder_size_entry.get()
            model.max_folder_size_units = view.folder_size_units_combobox.get()
            model.auto_delete = view.auto_delete_checkbutton_var.get()
            model.download_frequency = view.update_frequency_entry.get()
            model.download_frequency_units = view.art_check_frequency_combobox.get()
            model.create_description = view.create_description_checkbutton_var.get()
        
        except Exception as e:
            self.log_message("Error updating File Management Model:\n" + str(e), 'warning')

        else:
            self.log_model_fields(model)

    def update_file_artwork_criteria_model(self):

        model = self.model.artwork_criteria_model
        view = self.view.artwork_criteria_frame

        try:

            model.date_start = view.date_start_entry.get()
            model.date_start_age = view.date_start_age.get()
            model.date_end = view.date_end_entry.get()
            model.date_end_age = view.date_end_age.get()
            model.artist = view.artist_combobox.get()
            model.type = view.art_type_combobox.get()
            model.predominant_color = view.choose_color_entry.get()
            model.fetch_rare_art = view.rarity_checkbutton_var.get()
            model.style = view.style_combobox.get()

        except Exception as e:
            self.log_message("Error updating File Management Model:\n" + str(e), 'warning')

        else:
            self.log_model_fields(model)

</code></pre>

## <a id="creating-the-backend"></a>Creating the Backend

Let's create a new file in the root directory named `api.py`. This is where we'll be making a connection with Artic's servers. To accomplish this, we'll use the `requests` library:

`api.py`:
```python
import requests
import os

web_api = 'https://api.artic.edu/api/v1/'
local_api = os.getcwd() + '/artic-api-data/json/'
url = "not specified"


def get(endpoint):

    return requests.get(url + endpoint)


def post(endpoint, query):

    # example_query = {
    #     'q': 'cats',
    #     'query': {
    #         'term': {
    #             'is_public_domain': True,
    #         },
    #     },
    # }

    return requests.post(url, json=query)



if __name__ == "__main__":
    url = web_api

    response = get('artworks')

    print(response.json())


```

`requests` is not a built-in library, so you may have to install it: `pip install requests`. Once you run `api.py`, you should get a fat chunk of JSON in your output. And that's pretty much the basic idea! We can check out the [documentation](https://api.artic.edu/docs/#introduction) to learn more. Later on, we can add support for images stored locally.

## <a id="populating-our-gui-fields-with-api-data"></a>Populating our GUI Fields with API Data
Right now, our GUI dropdowns (artist, type, style) are empty. ARTIC's search is powered by [ElasticSearch](https://www.elastic.co/what-is/elasticsearch), and we'll need to formulate a query using ElasticSearch's [Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html) to get possible field values.

We'll import `api.py` into `model.py` and send our query from there. 

`model.py`:
```python
+ import api
class Model():
    def __init__(self):
        self.file_management_model = FileManagementModel()
        self.artwork_criteria_model = ArtworkCriteriaModel()

    def populate_artists(self):
        api.get('query goes here')
    
    ...
```





### <a id="forming-a-connection"></a>Forming a Connection



- validating new values in model, updating view accordingly
- creating backend to communicate with artic
- populating comboboxes with artic options
- implementing file management options

<!-- I figure it's best to do basic UI validation in the view (e.g. only integers in the "Max Picture Count" field), and anything more complicated/important("Business Logic")c  -->

<!-- 
Alternatively, we could use [tkinter's validation](https://www.pythontutorial.net/tkinter/tkinter-validation/) in the view, but we'll do our validation in the model. I like the explanation given [here](https://stackoverflow.com/a/5607545) as to why it's a better idea. -->
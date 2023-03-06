---
title: Audio Plugins
subtitle: "Part 1/3: Learning about CLAP"
excerpt: What does it take to build an audio plugin?
reason: To learn about audio plugins on modern systems && start using vim
disclaimer:
toc: true
use-math: true
use-raw-images: false
layout: post
author: Evan
header-image: /assets/images/blog-images/audio-plugins/part-one/sine-wave.png
header-image-alt: "Image of sine wave from http://www.tronola.com/moorepage/Sine.html" 
header-image-title: "The basis for all sounds: the sine wave."
tags: c++ music 
---

## An Introduction
---
### What is an Audio Plugin? 


An audio plugin is a piece of software (most often a virtual instrument or effect) that integrates into a [Digital Audio Workstation(DAW)](https://en.wikipedia.org/wiki/Digital_audio_workstation) such as [Reaper](reaper.fm) or [Ableton Live](ableton.com). There are quite a few different audio plugin formats - the most popular ones being:
- [VST3](https://www.steinberg.net/technology/) - Steinberg's closed-source solution turned open-source
- [AUv3](https://developer.apple.com/documentation/audiotoolbox/audio_unit_v3_plug-ins) - The iOS standard
- [AAX](https://www.avid.com/avid-plugins-by-category) - Avid/ProTools' solution
- Standalone - As the name would imply, these types of plugins don't require any host DAW. They can be launched and immediately tinkered with. Like NotePad.

Many developers release their audio plugins under multiple formats - often by using licensed tools like [JUCE](https://juce.com/).


---
### Choosing a Format
[Each format has their pros and cons](https://lwn.net/Articles/890272/). After starting and abandoning [VST3](https://github.com/eldun/eldun.github.io/blob/source/_drafts/simple-synth.md)(a pain on Linux... I might revisit VST3 on Windows.) and [LV2](https://github.com/eldun/eldun.github.io/blob/source/_drafts/simple-lv2-synth.md)(Plugin GUIs wouldn't show in Reaper) projects on Linux, I'm ready to try [CLAP](https://cleveraudio.org/). Fingers are crossed.

---
#### Why Choose CLAP?
[So many](https://cleveraudio.org/the-story-and-mission/) [reasons](https://u-he.com/community/clap/). 

<!--### What is LV2?
From [lv2pkug.in](https://lv2plug.in/): 
> LV2 is an extensible open standard for audio plugins. LV2 has a simple core interface, which is accompanied by extensions that add more advanced functionality.
>
> Many types of plugins can be built with LV2, including audio effects, synthesizers, and control processors for modulation and automation. Extensions support more powerful features, such as:
>
> - Platform-native UIs
> - Network-transparent plugin control
> - Portable and archivable persistent state
> - Non-realtime tasks (like file loading) with sample-accurate export
> - Semantic control with meaningful control designations and value units
> - The LV2 specification and accompanying code is permissively licensed free software, with support for all major platforms.
  

### Why Choose LV2?
I originally was going to create a VST3 synth([I even started a blog post :c](https://github.com/eldun/eldun.github.io/blob/source/_drafts/simple-synth.md)), but found Steinberg's [documentation](https://steinbergmedia.github.io/vst3_dev_portal/pages/) to be lacking and poorly organized - especially for the Linux platform, which is where I'm doing most of my coding as of late. LV2, on the other hand is platform-agnostic, [well-documented](https://lv2plug.in/pages/developing.html), and open-source from the start. 

[Here's a list of reasons to use LV2 straight from the source](https://lv2plug.in/pages/why-lv2.html). 
-->

---
### What Does an Audio Plugin Look Like?
There are thousands upon thousands of plugins out there - ranging from minimalist retro synths and complex rhythm sequencers to Karplus-Strong string modelers and destructive bit-crushers. Here are some of my favorites:

<span class="row-fill">
![Vital](/assets/images/blog-images/audio-plugins/part-one/vital.jpg)
![Dexed](/assets/images/blog-images/audio-plugins/part-one/dexed.png)
</span>
<span class="row-fill">
[Vital](vital.audio)
[Dexed](https://asb2m10.github.io/dexed/)
</span>



<span class="row-fill">
![Valhalla Freq Echo](/assets/images/blog-images/audio-plugins/part-one/valhalla-delay.webp)
![BlueARP Arpeggiator](/assets/images/blog-images/audio-plugins/part-one/blue-arp.png)
</span> 
<span class="row-fill">
[Valhalla Freq Echo](https://valhalladsp.com/shop/delay/valhalla-freq-echo/)
[BlueARP Arpeggiator](https://omg-instruments.com/wp/?page_id=63) 
</span>

It should be noted that although flashy UIs are fun and often very useful, they're not necessary. Look at Reaper's built-in synth - ReaSynth:
![ReaSynth](/assets/images/blog-images/audio-plugins/part-one/reasynth.png) 

Many plugin effects are also often very sparse.

<!--## Setting Up LV2

### Resources
LV2 doesn't have an official guide, but comes with a few well-documented example plugins. There's also a "[book](https://lv2plug.in/book/#_introduction)" that walks through the included examples. 

A short list of development topics can be read about [here](https://lv2plug.in/pages/developing.html).

### Downloading LV2
At the time of this writing, LV2 can be downloaded from [LV2's homepage](https://lv2plug.in/). There's also a [gitlab repository](https://gitlab.com/lv2/lv2). 

### Installing LV2
[Installation instructions](https://gitlab.com/lv2/lv2/-/blob/master/INSTALL.md) are included in the LV2 download. 



#### Installing Dependency Meson
- [Meson](https://mesonbuild.com/index.html) is LV2's chosen build system.
- [Installing Meson](https://mesonbuild.com/Getting-meson.html): `sudo apt install meson`. 
- [Getting Started with Meson](https://mesonbuild.com/Quick-guide.html).

#### Configuration
> The build is configured with the setup command, which creates a new build directory with the given name:
>
> `meson setup build`

(Just run `meson setup build` from the LV2 root directory)

From within the newly created `build` directory, you can:
- [`meson compile`](https://gitlab.com/lv2/lv2/-/blob/master/INSTALL.md#building)
- [`meson test`](https://gitlab.com/lv2/lv2/-/blob/master/INSTALL.md#building)
- [`meson install`](https://gitlab.com/lv2/lv2/-/blob/master/INSTALL.md#installation)

> You may need to acquire root permissions to install to a system-wide prefix. For packaging, the installation may be staged to a directory using the DESTDIR environment variable or the --destdir option:
> 
> <pre><code class="language-console">
> DESTDIR=/tmp/mypackage/ meson install
> 
> meson install --destdir=/tmp/mypackage/
> </code></pre> 

> By default, on UNIX-like systems, everything is installed within the <code>prefix</code>,
and LV2 bundles are installed in the "lv2" subdirectory of the <code>libdir</code>.  On
other systems, bundles are installed by default to the standard location for
plugins on the system. The bundle installation directory can be overridden
with the <code>lv2dir</code> option.
> The specification bundles are run-time dependencies of LV2 applications.
Programs expect their data to be available somewhere in `LV2_PATH`.  See
[http://lv2plug.in/pages/filesystem-hierarchy-standard.html](http://lv2plug.in/pages/filesystem-hierarchy-standard.html ) for details on the
standard installation paths.

> Configuration options(such as `lv2dir`) can be inspected with the `configure` command from within the `build` directory:
> 
> <pre><code class="language-console">
> cd build
> meson configure
> </code></pre> 

> Options can be set by passing C-style "define" options to configure:
>
> `meson configure -Dc_args="-march=native" -Dprefix="/opt/mypackage/"`
>
>
> Note that some options, such as strict and werror are for
developer/maintainer use only.  Please don't file issues about anything that
happens when they are enabled.
-->



---
## Setting up an Environment for CLAP
[CLAP isn't widely supported yet](https://clapdb.tech/category/hostsdaws). However, [BitWig](bitwig.com) - a DAW that's been gaining a lot of steam recently - supports it, and my current DAW of choice - [Reaper](reaper.fm) ~~[may be supporting it before long](https://forum.cockos.com/showthread.php?t=267906)~~ supports it on the dev branch, as of [less than a month ago](https://audiosex.pro/threads/reaper-c-l-a-p-support-now-a-reality.65864/). I'll be using Reaper v6.68+dev1004 (October 4).

~~In the meantime, I'll be using [Qtractor](https://qtractor.org/), because it's free. Installation instructions can be found [here](https://qtractor.org/qtractor-index.html#Installation). Make sure to have all the dependencies installed (I was missing some qt5 ones. Also, who names these qt5 packages? They're all over the place.)~~

Just to make sure everything was set up correctly, I installed [dexed](https://github.com/asb2m10/dexed) from source and tested it in Reaper.

![The CLAP version of dexed running in Reaper](/assets/images/blog-images/audio-plugins-synth/reaper-clap-dexed.png) 

---
## Learning to Create CLAP Plugins
---
### Where to Start?
I don't know much about creating plugins, and unfortunately, it looks like the ["Getting Started" page has a ways to go](https://cleveraudio.org/developers-getting-started/). 

![CLAP Documentation Under Construction](/assets/images/blog-images/audio-plugins/part-one/clap-getting-started.png) 

The way forward is through [example](https://github.com/free-audio/clap#examples) and [this youtube playlist](https://www.youtube.com/playlist?list=PLqRWeSPiYQ64DhTiE2dEIF5xRIw0s5XLS)(Developing with CLAP - Jürgen Moßgraber).

Actually, I watched the videos and they don't help that much. Let's move on.

---
### Building Example Plugins
[This repo](https://github.com/free-audio/clap-plugins) is full of juicy info on CLAP plugins.

The repo has a lengthy note about GUIs, builds and symbols:

> The plugins use Qt for the GUI.
>
> It is fine to dynamically link to Qt for a host, but it is very dangerous for a plugin.
> 
> Also one very important aspect of the plugin is the distribution. Ideally a clap plugin should be self contained: it should not rely upon symbols from the host, and it should export only one symbol: clap_entry.
> 
> You should be aware that even if you hide all your symbols some may still remain visible at unexpected places. Objective-C seems to register every classes including those coming from plugins in a flat namespace. Which means that if two plugins define two different Objective-C classes but with the same, they will clash which will result in undeflined behavior.
> 
> Qt uses a few Objective-C classes on macOS. So it is crucial to use QT_NAMESPACE.
> 
> We have two different strategies to work with that.
> 
> local: statically link every thing
> remote: start the gui in a child process
> 1. has the advantage of being simple to deploy. 2. is more complex due to its inter-process nature. It has a few advantages:
> 
> if the GUI crash, the audio engine does not
> the GUI can use any libraries, won't be subject to symbol or library clash etc...
> We abstracted the relation between the plugin and the GUI: AbstractGui and AbstractGuiListener which lets us transparently insert proxies to support the remote model.
> 
> The GUI itself work with proxy objects to the parameters, transport info, ... They are then bound into QML objects. See Knob.qml and parameter-proxy.hh.
> 
> We offer two options:
> 
> static build, cmake preset: ninja-vcpkg or vs-vcpkg on Windows.
> dynamic builg, cmake preset: ninja-system
> Static builds are convenient for deployment as they are self containded. They use the local gui model.
> 
> Dynamic builds will get your started quickly if your system provides Qt6, and you have an host that do not expose the Qt symbols. Static builds will require more time and space.

([Difference between build methods](https://stackoverflow.com/a/311889))

Build instructions for different platforms can be found [here](https://github.com/free-audio/clap-plugins#building-on-various-platforms).


The plugins will be installed to `usr/local/lib`. From there, you can try them out in your preferred plugin host.

---
### A Simpler Example
There's a lot going on in the last section. A minimal example (linked to from the official CLAP repository) can be found [here](https://github.com/schwaaa/clap-imgui.git). I highly reccommend reading through [the repo's README](https://github.com/schwaaa/clap-imgui#readme). 


Excluding reference and image files, these are the contents of the repo:
<pre><code class="language-treeview">

./
|-- build/
|   |-- lin/
|   |-- mac/
|   `-- win/
`-- src/
    |-- clap/
    |-- glfw/
    |-- gui.cpp
    |-- imgui/
    |-- imgui_base.cpp
    |-- imgui_lin.cpp
    |-- imgui_mac.mm
    |-- imgui_win.cpp
    |-- main.cpp
    |-- main.h
    |-- plugin.cpp
    |-- plugin_impl_0.cpp
    `-- plugin_impl_1.cpp

</code></pre> 

To build these examples, all we have to do(on Linux) is navigate to `build/lin` and execute the makefile there  with `make`.

![Simple CLAP Example 1](/assets/images/blog-images/audio-plugins/part-one/simple-clap-example-1.gif) 
![Simple CLAP Example 2](/assets/images/blog-images/audio-plugins/part-one/simple-clap-example-2.gif) 

The resulting `.clap` file should show up right next to the makefile. If you'd like to try these plugins out, you can add our current directory to your host's CLAP path or copy the generated CLAP file to `usr/local/lib` - the default path for CLAP plugins.

---
#### Understanding the Examples

---
##### The `main` File
You can see in `main.h` that the only `#include` is `clap.h`, which allows us to work with CLAP. This is also where our customized plugin struct is defined (With members `clap_plugin`, `clap_plugin_params`, and `clap_plugin_gui` from the included `clap.h`. If you would like to know more about these 'extensions' (params & gui), check out the well-documented [source code files](https://github.com/free-audio/clap/tree/main/include/clap/ext). 

---
##### The `plugin` File
We don't really have to worry about this file - it's where our plugins are constructed and passthroughs are located. Genericized plugin, GUI, and param calls are also set up here.

---
##### The `plugin_impl` Files
These are our actual plugins! Here is where we describe our plugins and their parameters, as well as how they behave, and what they look like (at least in this example).
Let's take a look at the tone generator plugin once more:
![Simple CLAP Example 2](/assets/images/blog-images/audio-plugins/part-one/simple-clap-example-2.gif) 

You can see how the turning of knobs is continually processed in the `process` functions. Things are kicked off with this one:
<pre><code class="language-cpp">
template &lt;class T>
  clap_process_status \_plugin\_impl__process(const clap_process &#42;process,
    int num_channels, int start_frame, int end_frame,
    double *start_param_values, double *end_param_values,
    T **out)
  {
    if (!out) return CLAP_PROCESS_ERROR;

    double start_vol = start_param_values[PARAM_VOLUME];
    double end_vol = end_param_values[PARAM_VOLUME];
    double d_vol = (end_vol-start_vol) / (double)(end_frame-start_frame);

    double start_pitch = start_param_values[PARAM_PITCH];
    double end_pitch = end_param_values[PARAM_PITCH];
    double start_phase=m_phase, d_phase=0.0;
    if (end_pitch >= 0.0)
    {
      if (start_pitch &lt; 0.0) start_phase=0.0;
      else start_pitch += start_param_values[PARAM_DETUNE]*0.01;
      end_pitch += end_param_values[PARAM_DETUNE]*0.01;
      double freq = 440.0 * pow(2.0, (end_pitch-57.0)/12.0);
      d_phase = 2.0 * _PI * freq / (double)m_srate;
    }

    for (int c=0; c &lt; num_channels; ++c)
    {
      T *cout=out[c];
      if (!cout) return CLAP_PROCESS_ERROR;

      if (d_phase > 0.0)
      {
        double vol = start_vol;
        double phase = start_phase;
        for (int i=start_frame; i &lt; end_frame; ++i)
        {
          cout[i] = sin(phase)*vol;
          phase += d_phase;
          vol += d_vol;
        }
      }
      else
      {
        memset(cout+start_frame, 0, (end_frame-start_frame)*sizeof(T));
      }
    }

    m_phase += (double)(end_frame-start_frame)*d_phase;

    return CLAP_PROCESS_CONTINUE;
  }

</code></pre> 


And they continue being kicked off with this one:
<pre><code class="language-cpp">
clap_process_status plugin_impl__process(const clap_process &#42;process)
  {
    double cur_param_values[NUM_PARAMS];
    for (int i=0; i &lt; NUM_PARAMS; ++i)
    {
      cur_param_values[i]=m_param_values[i];
    }

    clap_process_status s = -1;
    if (process && process->audio_inputs_count == 0 &&
      process->audio_outputs_count == 1 && process->audio_outputs[0].channel_count == 2)
    {
      // handling incoming parameter changes and slicing the process call
      // on the time axis would happen here.

      if (process->audio_outputs[0].data32)
      {
        s = _plugin_impl__process(process, 2, 0, process->frames_count,
          m_last_param_values, cur_param_values,
          process->audio_outputs[0].data32);
      }
      else if (process->audio_outputs[0].data64)
      {
        s = _plugin_impl__process(process, 2, 0, process->frames_count,
          m_last_param_values, cur_param_values,
          process->audio_outputs[0].data64);
      }
    }

    for (int i=0; i &lt; NUM_PARAMS; ++i)
    {
      m_last_param_values[i]=m_param_values[i];
    }

    if (s &lt; 0) s = CLAP_PROCESS_ERROR;
    return s;
  }
</code></pre> 

The other important classes are all the `ImGui` ones, like `draw()`.

---
##### The `\*gui\*` Files
These files are where our Plugin struct member actually interfaces with OpenGL through [Dear Imgui](https://github.com/ocornut/imgui) and [GLFW](https://www.glfw.org/) 

---
##### The GUI
The developer of these simpler plugins - schwaaa - explains why he's using [Dear Imgui](https://github.com/ocornut/imgui):
 
> The UI for this example is presented via [Dear ImGui](https://github.com/ocornut/imgui). The ImGui concept is easy to misunderstand so please read [the Dear ImGui README](https://github.com/ocornut/imgui#readme). The key concept is that the caller (this plugin) does not retain any state related to the UI. This allows developers to quickly prototype controls.
> 
> 100% of the plugin's UI code is in `plugin_impl__draw()`, a single small function. For example, this is the code for the volume slider, which draws the control, handles mouse and keyboard input, and links the control to the voldb variable:
> 
> `ImGui::SliderFloat("Volume", &voldb, -60.0f, 12.0f, "%+.1f dB", 1.0f);`
> 
> You have some control over the appearance and placement of the control, but the primary design goal is simplicity and ease of programmer use. ImGui is not typically used for end-user UI.
> 
> ImGui is helpful for this example because:
> - Permissively licensed
> - No external dependencies
> - Very easy to interact with


---
##### The Makefile
You may have noticed that a single `.clap` file contains two plugins. You can step through the [makefile](https://github.com/schwaaa/clap-imgui/blob/main/build/lin/Makefile) to see how this happens(and here's a [makefile refresher](https://www.cs.colby.edu/maxwell/courses/tutorials/maketutor/), if you're in need), and how we end up with our plugins from dozens of source files. The most important line is where the actual compilation takes place (line 57).

---
### Closing Thoughts
Creating audio plugins from scratch turned out to be a bit less straightforward than I expected. I was especially hoping for more in the way of documentation. The next post in this series will be focused on creating our own arpeggiator, and the following on creating a sampler. 

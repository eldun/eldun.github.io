---
title: Coding up an LV2 Synth Audio Plugin 
subtitle: 
excerpt: Are synths as fun to code as they are to play?
reason: To learn about audio on modern systems && start using vim exclusively
disclaimer:
toc: true
use-math: true
use-raw-images: false
layout: post
author: Evan
header-image: /assets/images/blog-images/lv2-synth
header-image-alt: "Image of sine wave from http://www.tronola.com/moorepage/Sine.html" 
header-image-title:"The basis for all sounds: the sine wave."
tags: audio music c++
---

## An introduction
### What is an Audio Plugin? 
An audio plugin is a piece of software (most often a virtual instrument or effect) that integrates into a [Digital Audio Workstation(DAW)](https://en.wikipedia.org/wiki/Digital_audio_workstation) such as [Reaper](reaper.fm) or [Ableton Live](ableton.com). There are quite a few different audio plugin formats - the most popular ones being:
- [VST3](https://www.steinberg.net/technology/) - Steinberg's closed-source solution turned open-source
- [AUv3](https://developer.apple.com/documentation/audiotoolbox/audio_unit_v3_plug-ins) - The iOS standard
- [AAX](https://www.avid.com/avid-plugins-by-category) - Avid/ProTools' solution
- Standalone - As the name would imply, these types of plugins don't require any host DAW. They can be launched and operated. Like NotePad.

Many developers release their audio plugins under multiple formats - often by using licensed tools like [JUCE](https://juce.com/).


### What is LV2?
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

### What Does an Audio Plugin Look Like?
There are thousands upon thousands of plugins out there - ranging from minimalist retro synths and complex rhythm sequencers to Karplus-Strong string modelers and destructive bit-crushers. Here are some of my favorites:

[Vital](vital.audio)
![Vital](/assets/images/blog-images/simple-synth/vital.jpg)
[Dexed](https://asb2m10.github.io/dexed/)
![Dexed](/assets/images/blog-images/simple-synth/dexed.png)
![Valhalla Freq Echo](/assets/images/blog-images/simple-synth/valhalla-delay.webp)
[Valhalla Freq Echo](https://valhalladsp.com/shop/delay/valhalla-freq-echo/)
![BlueARP Arpeggiator](/assets/images/blog-images/simple-synth/blue-arp.png)
[BlueARP Arpeggiator](https://omg-instruments.com/wp/?page_id=63) 





## Setting Up LV2

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


---
title: Writing a Simple Synth VST Plug-in
subtitle: 
excerpt: Are synths as fun to write as they are to play with?
reason: To learn about generating sounds on modern systems && start using vim exclusively.
disclaimer:
toc: true
use-math: true
use-raw-images: false
layout: post
author: Evan
header-image: /assets/images/blog-images/simple-synth/sine-wave.png
header-image-alt: "The basis for all sounds: the sine wave."
header-image-title:"The basis for all sounds: the sine wave."
tags: synthesis music c++
---


## What is VST? 
VST stands for "Virtual Studio Technology" - it's an audio plug-in software interface that integrates virtual instruments and effects into digital audio workstations such as [Reaper](reaper.fm) or [Ableton Live](ableton.com). If you'd like to learn more, you can check out [Wikipedia's VST page](https://en.wikipedia.org/wiki/Virtual_Studio_Technology). 

## What Does a VST Plug-in Look Like?
There are thousands upon thousands of VSTs out there - ranging from minimalist retro synths and complex rhythm sequencers to Karplus-Strong string modelers and destructive bit-crushers. Here are some of my favorites:

<span class="row">
<span class="captioned-image">
[Vital](vital.audio)
![Vital](/assets/images/blog-images/simple-synth/vital.jpg)
</span>
<span class="captioned-image">
[Dexed](https://asb2m10.github.io/dexed/)
![Dexed](/assets/images/blog-images/simple-synth/dexed.png)
</span>
</span>

<span class="row">
<span class="captioned-image">
![Valhalla Freq Echo](/assets/images/blog-images/simple-synth/valhalla-delay.webp)
[Valhalla Freq Echo](https://valhalladsp.com/shop/delay/valhalla-freq-echo/)
</span>
<span class="captioned-image">
![BlueARP Arpeggiator](/assets/images/blog-images/simple-synth/blue-arp.png)
[BlueARP Arpeggiator](https://omg-instruments.com/wp/?page_id=63) 
</span>
</span>

## Starting Small
I've done a small amount of coding that involved audio before, but that was for Android - I know almost nothing about creating VSTs. Thankfully, there's a lot of literature out there - I'll be following [this guide](http://www.martin-finke.de/blog/tags/making_audio_plugins.html) by Martin Finke. The first step on the journey will be creating a simple distortion plug-in (rock and roll!) to get familiar with the tools and concepts involved in VST creation:
> We will use C++ and the WDL-OL library. It is based on Cockos WDL (pronounced whittle). It basically does a lot of work for us, most importantly:  
- Ready-made Xcode / Visual Studio Projects 
- Create VST, AudioUnit, VST3 and RTAS formats from one codebase: Just choose the plugin format and click run! 
- Create 32/64-Bit executables 
- Make your plugin run as a standalone Win/Mac application 
- Most GUI controls used in audio plugins 

We don't have to worry about the different VST formats thanks to IPlug - an abstraction layer that's part of WDL.

## Installing Dependencies
The first order of business is to download the VST3 SDK from [Steinberg](https://www.steinberg.net/developers/). Unfortunately, the guide I'm following isn't tailored for Linux users - I'll have to do some digging as to actually make use of it. So far, the most promising steps I've found are [here (system setup)](https://steinbergmedia.github.io/vst3_dev_portal/pages/Getting+Started/How+to+setup+my+system.html#for-linux) and [here (building the example)](https://steinbergmedia.github.io/vst3_dev_portal/pages/Tutorials/Building+the+examples+included+in+the+SDK+Linux.html#part-2-building-the-examples-on-linux). Note that to install dependencies, you can run the script "setup_linux_packages_for_vst3sdk.sh" included in the VST3_SDK/tools folder.

Now we have to install [cmake](https://cmake.org/install/) to control the compilation process. I ran into issues on my Chromebook running executing the bootstrap file - extracting (and installing) the cmake tarball to /home instead of /mnt solved my issues.

Now we need a VST host - I already have Reaper installed, so that's what I'll be using.


                 clone the [WDL repository](https://github.com/olilarkin/wdl-ol)

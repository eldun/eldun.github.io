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

## Building the Included Examples
Now we have to install [cmake](https://cmake.org/install/) to control the compilation process. I ran into issues on my Chromebook running executing the bootstrap file - extracting the cmake tarball to (and installing from) /home instead of /mnt solved my issues.

A helpful tutorial on CMake can be found [here](https://cmake.org/cmake/help/latest/guide/tutorial/index.html)
 

The next step is to construct our build folder with CMake, which will include some example VSTs.
```
mkdir build
cd build

cmake ../VST_SDK/vst3sdk/
```
The resulting `build/VST3/Debug` folder is full of example VSTs:
```
adelay.vst3                helloworld.vst3            multiple_programchanges.vst3  prefetchable.vst3
again-sampleaccurate.vst3  helloworldWithVSTGUI.vst3  noteexpressionsynth.vst3      programchange.vst3
againsimple.vst3           hostchecker.vst3           noteexpressiontext.vst3       syncdelay.vst3
again.vst3                 legacymidiccout.vst3       panner.vst3
channelcontext.vst3        mda-vst3.vst3              pitchnames.vst3
```
Now we need a VST host - I already have Reaper installed, so that's what I'll be using. After setting up the path to our new VSTs in Reaper, we can load some up:

![Example Steinberg VST Plug-ins loaded up in Reaper](/assets/images/blog-images/simple-synth/vst-examples.png)


## Using VSTGUI
### Setup
(Following the article [here](https://steinbergmedia.github.io/vst3_dev_portal/pages/Tutorials/Index.html#use-vstgui-to-design-a-user-interface)) 


> If you have created your project with the VST 3 Project Generator and check the "Use VSTGUI" (I didn't - as far as I can tell it's only for Mac/Windows) you can directly jump to Part 2 of this tutorial.

Since that's the case, I had to do some digging. Cloning the VST 3 Project Generator from [Github](https://github.com/steinbergmedia/vst3projectgenerator), I found a script that I could run to generate a project at vst3projectgenerator/script/GenerateVST3Plugin.cmake. Here's the readme:

> ## Usage

> Execute on command line:

```console
$ cmake -P GenerateVST3Plugin.cmake
```

The script will output all variables and its current values. In order to adapt variables, edit

```console
vst3plugingenerator/cmake/modules/SMTG_VendorSpecifics.cmake
```

file to your needs.

After the script has finished you will find a

```console
vst3plugingenerator/myplugin
```

folder in the directory the script was executed in.

> Before using the inline UI editor, you must make sure that you use the Steinberg::Vst::EditController class as a base of your own edit controller and that you have used the Steinberg::Vst::Parameter class or any subclass of it for your parameters. Otherwise the inline UI editor won't work properly.

> Next you have to add vstgui to your project. For cmake users, you can just add the vstgui_support library to your target:

> target_link_libraries(${target} PRIVATE vstgui_support)

I'm not yet an expert with Cmake, so I looked at the included plugin example CMakeLists.txt at /VST_SDK/my_plugins/helloworld_with_VSTGUI/ to get a better idea of what to do:

```

if(NOT SMTG_ADD_VSTGUI)
    return()
endif()

cmake_minimum_required(VERSION 3.15.0)

project(smtg-vst3-helloworldWithVSTGUI
    VERSION ${vstsdk_VERSION}.0
    DESCRIPTION "Steinberg VST 3 helloworldWithVSTGUI example"
)

smtg_add_vst3plugin(helloworldWithVSTGUI     
    include/plugcontroller.h
    include/plugids.h
    include/plugprocessor.h
    include/version.h
    source/plugfactory.cpp
    source/plugcontroller.cpp
    source/plugprocessor.cpp
)

if(SMTG_MAC)
    smtg_target_set_bundle(helloworldWithVSTGUI
        BUNDLE_IDENTIFIER "com.steinberg.helloworldWithVSTGUI"
        COMPANY_NAME "Steinberg Media Technologies"
)
elseif(SMTG_WIN)
    target_sources(helloworldWithVSTGUI
        PRIVATE 
            resource/info.rc
)
endif()

configure_file(${SDK_ROOT}/cmake/templates/projectversion.h.in projectversion.h)

target_include_directories(helloworldWithVSTGUI PUBLIC
    "${PROJECT_BINARY_DIR}"
)

target_link_libraries(helloworldWithVSTGUI
    PRIVATE
        sdk
        vstgui_support
)

smtg_target_add_plugin_resources(helloworldWithVSTGUI
    RESOURCES
        resource/plug.uidesc
        resource/background.png
        resource/animation_knob.png
        resource/onoff_button.png
        resource/background_2x.png
        resource/animation_knob_2x.png
        resource/onoff_button_2x.png
        resource/background_3x.png
        resource/animation_knob_3x.png
        resource/onoff_button_3x.png
)

smtg_target_add_plugin_snapshots(helloworldWithVSTGUI
    RESOURCES
        resource/41E3A6A2C1991743A64945DC3FB7D51D_snapshot.png
        resource/41E3A6A2C1991743A64945DC3FB7D51D_snapshot_2.0x.png
)
```


Next, you have to

> alter your project settings to add a preprocessor definition to your debug build:

> VSTGUI_LIVE_EDITING=1
> With cmake, this would look like this:

> target_compile_definitions(${target} PUBLIC$<$<CONFIG:Debug>:VSTGUI_LIVE_EDITING=1>) 


However, I **think** that the SMTG_ADD_VSTGUI option in '/vst3sdk/CMakeLists.txt` takes care of this (see CMakelists.txt above.

> Finally, you have to modify your edit controller class to overwrite the createView() method

As far as I could tell, the method they show in [the article](https://steinbergmedia.github.io/vst3_dev_portal/pages/Tutorials/Use+VSTGUI+to+design+a+UI.html) and the one in `vst3sdk/vstgui4/vstgui/plugin-bindings/vst3editor.cpp` are identical. 

### Using the VSTGUI UI Editor
Running the plugin in our DAW, we can see there's a popup to use the visual editor:
![UI Editor Popup Option](/assets/images/blog-images/simple-synth/ui-editor-popup.png)
![UI Editor](/assets/images/blog-images/simple-synth/ui-editor.png)

Note that we have to save any changes within the editor (which would be the uidesc file), and we have to build our project after any changes to the uidesc file to see our changes.


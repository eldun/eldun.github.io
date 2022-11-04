---
title:  Audio Plugins
subtitle: "Part 2/3: Creating a CLAP Arpeggiator"
excerpt: Now that we know what the deal is with CLAP, we can create a simple MIDI processor.
reason: 
disclaimer:
toc: true
use-math: true
use-raw-images: false
layout: post
author: Evan
header-image: /assets/images/blog-images/clap/part-one/
header-image-alt: "Image of from blank.com"
header-image-title: ""
tags: c++ music audio-plugins 
---

### The Idea
We already have multiple example plugins from [free-audio](https://github.com/free-audio/clap) and [schwaaa](https://github.com/schwaaa/clap-imgui), but there's nothing like doing it yourself. I figured a simple arpeggiator with a rudimentary GUI would be a decent place to start. As per usual, I'm not trying to make the wildest arpeggiator in the world here. Tryhard mode will be the next part in the series.

### Creating a "New" Plugin
If you've found your way here through my last post on audio plugins, you've likely already read [schwaaa's README](https://github.com/schwaaa/clap-imgui#readme), but if you haven't, I'd recommend doing so.

Anyway, this is the general plan for creating an arpeggiator:

> The example code exports two very basic plugins, Volume/Pan and Tone Generator. You should be able to prototype basic plugins by editing (or adding) a src/plugin_impl_#.cpp file, which contains the actual audio plugin and UI implementation. The plugin descriptor and parameter definitions are at the top of the file, and plugin_impl__draw() contains the plugin-specific UI code.
>
> If you want to extend your plugin to add support for other CLAP extensions, you will need to add scaffolding code to src/plugin.cpp, similar to how the gui and parameter extensions are handled.

We will likely have to add extensions like `note-ports.h` later on.

### Adapting schwaaa's Volume Plugin to an Arp
Almost all of the code we'll be concerned with will be contained within `plugin_impl_2.cpp`, which is (as of right now) a copy of `plugin_impl_0.cpp`. Let's step through, block by block, and make our changes.

#### Info and Dexcriptors 
The first step is to accurately describe our plugin, of course:
```cpp

static clap_plugin_descriptor _descriptor =
{
  CLAP_VERSION,
  "net.eldun.clap-example-2",
  "CLAP Arp"
  "eldun",
  "eldun.github.io",
  "eldun.github.io",
  "eldun.github.io",
  "0.0.1",
  "Arpeggiator",
  _features
};
```



































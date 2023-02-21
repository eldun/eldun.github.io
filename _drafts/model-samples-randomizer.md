---
title: "Mixing it up:"
subtitle: "Creating Random Sample Kits on the Model:Samples"
excerpt: "One of my favorite samplers lacks the ability to create a random kit on the fly - are there any workarounds to do so?"
use-math: true
use-raw-images: false
toc: true
layout: post
author: Evan
header-image: /assets/images/blog-images/model-samples/model-samples.png
header-image-alt: The knobby Model:Samples surrounded by disembodied plaster hands.
header-image-title: The Elektron Model:Samples, as portrayed by Elektron.
tags: python scripting music
---

<a id="continue-reading-point"></a>

### What is the Model:Samples?
The [Model:Samples](https://www.elektron.se/us/modelsamples-explorer) (hereinafter referred to as the Samples) is a capable mid-range six-track sample mangler with a powerful built-in sequencer. You can check out a review of it below to get accquainted with its "workflow":

<iframe width="560" height="315" src="https://www.youtube.com/embed/y3NBzKJ9R5A" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

If you didn't watch the video, I'll cover the basics for you:


- 6 audio tracks (all of which may be used as MIDI tracks instead)
- 6 × velocity-sensitive pads
- 96 projects
- 96 patterns per project
- Elektron sequencer up to 64 steps with unique length and scale settings per track
- real-time or grid recording of notes and parameters
- 64 MB sample memory
- 1 GB storage

1 GB of storage might not sound like a lot, but samples are often very short - the storage goes a *long* way.

### The Goal
Many samplers/sample players have the ability to shuffle the active samples; a feature intended to spark creativity or simply create a new, weird "kit". The Samples, being Elektron's more budget-friendly device (as opposed to the [Digitakt](https://www.elektron.se/us/digitakt-explorer), lacks this feature, among others (which I won't get into). I've found myself making beat after beat with the default kit, just because I hate the process of scrolling through all my folders and samples - it can really suck up some time! I've grown tired of the factory kits, and have realized that there's a workaround.


### The Solution
Thankfully, the devs included a feature to automatically load all samples in a folder:

![Details on loading an entire set of samples](/assets/images/blog-images/model-samples/load-folder.png) 

All we have to do is write a script to copy 6 random files from our desired sample library to their own folder. It's a bit hacky, but it'll still be loads faster for making completely stupid beats than browsing. Of course, I still want to reserve some space for my curated sounds on the Samples (for when I need to find and use the [Goldeneye sound](https://www.youtube.com/watch?v=wRl88VATFrs)).

The first party software used for communicating with and transferring samples to & from the Samples is [Elektron Transfer](https://www.elektron.se/us/download-support-transfer) - available for Mac and Windows. For Linux, the third party [Elektroid](https://github.com/dagargo/elektroid) works just as well.o

### The Gameplan
We'll be using Python. 

First, we should think about scope and how the user will interact with the program.

#### Scope
This is not a life-changing program and does not need to be terribly robust.

#### Usage
At the moment, following cp's example seems to make a lot of sense (Specifically, the first and second lines of the synopsis):

<pre><code class="language-terminal">
NAME
       cp - copy files and directories

SYNOPSIS
       cp [OPTION]... [-T] SOURCE DEST
       cp [OPTION]... SOURCE... DIRECTORY
       cp [OPTION]... -t DIRECTORY SOURCE...

DESCRIPTION
       Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.
</code></pre> 

### The Script 
To get started, we'll need to parse command line arguments. Most of what you would ever need to know can about command line arguments can be found [here](https://realpython.com/python-command-line-arguments). Late in the article, you'll find the [recommendation to use the existing Python standard library](https://realpython.com/python-command-line-arguments/#the-python-standard-library), [`argparse`](https://docs.python.org/3/library/argparse.html). 



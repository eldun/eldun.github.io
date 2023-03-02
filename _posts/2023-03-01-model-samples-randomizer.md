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
Many samplers/sample players have the ability to shuffle the active samples; a feature intended to spark creativity or simply create a new, weird "kit". The Samples, being Elektron's more budget-friendly device (as opposed to the [Digitakt](https://www.elektron.se/us/digitakt-explorer), lacks this feature, among others (which I won't get into). I've found myself making beat after beat with the default kit, just because the process of flippantly selecting samples by scrolling through all my shallow folders really sucks up some time! I've grown tired of the factory kits, and have realized that there's a wonky workaround.


### The Solution
Thankfully, the devs included a feature to automatically load all samples in a folder:

![Details on loading an entire set of samples](/assets/images/blog-images/model-samples/load-folder.png) 

All we have to do is write a script to copy 6 random files from our desired sample library to their own folder. It's hacky, but it'll still be loads faster for making completely stupid beats than browsing. Of course, I still want to reserve some space for my curated sounds on the Samples (like for when I need to find and use the [Goldeneye sound](https://www.youtube.com/watch?v=wRl88VATFrs)).

The first party software used for communicating with and transferring samples to & from the Samples is [Elektron Transfer](https://www.elektron.se/us/download-support-transfer) - available for Mac and Windows. For Linux, the third party [Elektroid](https://github.com/dagargo/elektroid) works just as well.

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

#### Parsing Arguments
To get started, we'll need to parse command line arguments. Most of what you would ever need to know can about command line arguments can be found [here](https://realpython.com/python-command-line-arguments). Late in the article, you'll find the [recommendation to use the existing Python standard library](https://realpython.com/python-command-line-arguments/#the-python-standard-library), [`argparse`](https://docs.python.org/3/library/argparse.html). 

One of the most useful parts of the documentation on `argparse` is an [overview of the \`add_argument\` method](https://docs.python.org/3/library/argparse.html#the-add-argument-method).

Using argparse, the start of our program will look like this:
<pre><code class="language-python">
import argparse


def init_argparse() -> argparse.ArgumentParser:
    # print('Initializing parser')
    parser = argparse.ArgumentParser(description='Create seqeuntially named directories - each containing six random files collated from the provided source directories')

    parser.add_argument('sources', nargs='+')
    parser.add_argument('dest', nargs=1)
    parser.add_argument('--kits', '-k',
                        nargs='?',
                        type=int,
                        default=DEFAULT_KIT_SIZE,
                        help='The number of output folders(\'kits\') to create. Default: ' + str(DEFAULT_KIT_SIZE))
    # print('Parser initialized')
    return parser

if __name__ == "__main__":
    parser = init_argparse()
    args = parser.parse_args() 
    print(args)
</code></pre> 

Let's do a quick test:
<pre><code class="language-python">
evan@evan-ThinkPad-E495:~/Projects/ModelSamplesRandomizer$ python3 msrandomizer.py goodmorning goodafternoon goodnight
</code></pre> 

The result:
<pre><code class="language-python">
Namespace(sources=['goodmorning', 'goodafternoon'], dest=['goodnight'], kits=25)
</code></pre> 

Perfect! We can access these values using dot notation (e.g. `args.sources`)

#### Generating the Kits
An excellent resource on working with files in python can be found [here](https://realpython.com/working-with-files-in-python/#pythons-with-open-as-pattern).

The procedure be as follows:
1. Select 6 unique random audio files from the supplied source(s) 
2. Create a directory (named sequentially in hex) and copy the files to it
3. Repeat until the desired number of kits is reached OR the size of the files copied reaches ~1 gig (the size of the Samples' drive)

To complete these steps, we'll be importing a few modules: 

- [`shutil`](https://docs.python.org/3/library/shutil.html) - High-level file operations (**sh**ell **util**ities)
- [`random`](https://docs.python.org/3/library/random.html)
- [`os`](https://docs.python.org/3/library/os.html)

Let's create a function `generate_kits`:

<pre><code class="language-python">def generate_kits(args) -> None:
    random_source = lambda: random.choice(args.sources)
    dest = args.dest[0]
    kit_count = args.kits

    current_kit_label = 0
    cumulative_size = 0


    for kit in range(kit_count):

        if cumulative_size > MAX_TRANSFER_LIMIT_IN_BYTES:
            exit_string = str.format('Max transfer size({} GiB) reached', cumulative_size/1024.0/1024.0/1024.0)
            sys.exit(exit_string)
        
        attempts = 0
        samples_added = 0
        kit_folder = f'{current_kit_label:x}'
        output_folder = os.path.join(dest, kit_folder)

        if os.path.isdir(output_folder):
            shutil.rmtree(output_folder)
    

        os.mkdir(output_folder)

        while samples_added < KIT_SIZE:
            if attempts > MAX_ATTEMPTS:
                exit_string = str.format('The maximum number of attempts({}) for creating a kit has been reached.', MAX_ATTEMPTS)
                sys.exit(exit_string)

            source = random_source() # Randomly choose a new source dir each iteration

            # Pick random file
            files = [os.path.join(path, filename)
                for path, dirs, files in os.walk(source)
                for filename in files]
            random_file = random.choice(files)

            # Only grab audio files
            if (os.path.isfile(random_file) and 
                random_file.lower().endswith(('.wav', '.mp3', '.aiff'))):

                shutil.copy(random_file, output_folder)

                copied_string = os.path.basename(random_file) + ' copied to ' + kit_folder
                cumulative_size += os.path.getsize(random_file)
                cumulative_size_string = '{:.2f} {}'.format(cumulative_size/1024.0/1024.0, 'MiB copied')

                # Columnated console output
                print(f'{copied_string:<50}{"":<10}{cumulative_size_string:<}'  )

                samples_added += 1

            else:
                attempts +=1


        current_kit_label = current_kit_label + 1
</code></pre> 

That's it! The complete code can be found [here](https://github.com/eldun/msrandomizer/blob/main/msrandomizer.py)

### Results
Check back in a couple days and I'll have made some preposturous beats with my ultra-fresh random kits.

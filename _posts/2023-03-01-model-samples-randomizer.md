---
title: "Mixing it up:"
subtitle: "Creating Random Sample Kits on the Model:Samples"
excerpt: "One of my favorite afforadable samplers lacks the ability to create random kits - are there any workarounds to do so?"
use-math: true
use-raw-images: false
toc: true
layout: post
author: Evan
header-image: /assets/images/blog-images/model-samples/model-samples.png
header-image-alt: The knobby Model:Samples surrounded by disembodied plaster hands.
header-image-title: The Elektron Model:Samples, as portrayed by Elektron.
tags: python scripting music ai
---

<a id="continue-reading-point"></a>


---

### What is the Model:Samples?
The [Model:Samples](https://www.elektron.se/us/modelsamples-explorer) (hereinafter referred to as the Samples) is a capable mid-range six-track sample mangler with a powerful built-in sequencer. You can check out a review of it below to get accquainted with its "workflow":

<iframe width="560" height="315" style="display: block; margin: auto;" src="https://www.youtube.com/embed/y3NBzKJ9R5A" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
If you didn't watch the video, I'll cover the basics for you:


- 6 audio tracks (all of which may be used as MIDI tracks)
- 6 × velocity-sensitive pads
- 96 projects
- 96 patterns per project
- Elektron sequencer up to 64 steps with unique length and scale settings per track
- real-time or grid recording of notes and parameters
- 64 MB sample memory
- 1 GB storage

1 GB of storage might not sound like a lot, but samples are often very short - the storage goes a *long* way.

---

### The Goal
Many samplers/sample players have the ability to shuffle the active samples; a feature intended to spark creativity or simply create a new, weird "kit". The Samples, being Elektron's more budget-friendly device (as opposed to the [Digitakt](https://www.elektron.se/us/digitakt-explorer)), lacks this feature, among others. I've found myself making beat after beat with the default kit, just because the process of flippantly selecting samples by scrolling through all my shallow folders really sucks up some time! I've grown tired of the factory kits, and have realized that there's a wonky workaround.


---

### The Solution
Thankfully, the devs included a feature to automatically load all samples in a folder:

![Details on loading an entire set of samples](/assets/images/blog-images/model-samples/load-folder.png) 

All we have to do is write a script to copy 6 random files from our desired sample library to their own folder. It's hacky, but it'll still be loads faster for making completely stupid beats than browsing. Of course, I still want to reserve some space for my curated sounds on the Samples (like for when I need to find and use the [Goldeneye sound](https://www.youtube.com/watch?v=wRl88VATFrs)).

The first party software used for communicating with and transferring samples to & from the Samples is [Elektron Transfer](https://www.elektron.se/us/download-support-transfer) - available for Mac and Windows. For Linux, the third party [Elektroid](https://github.com/dagargo/elektroid) works just as well.

---

### The Gameplan
We'll be using Python. 

First, we should think about scope and how the user will interact with the program.

---

#### Scope
This is not a life-changing program and does not need to be terribly robust.

---

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

---

### The Script 

---

#### Parsing Arguments
To get started, we'll need to parse command line arguments. Most of what you would ever need to know can about command line arguments can be found [here](https://realpython.com/python-command-line-arguments). Late in the article, you'll find the [recommendation to use the existing Python standard library](https://realpython.com/python-command-line-arguments/#the-python-standard-library), [`argparse`](https://docs.python.org/3/library/argparse.html). 

One of the most useful parts of the documentation on `argparse` is an [overview of the &apos;add_argument&apos; method](https://docs.python.org/3/library/argparse.html#the-add-argument-method).

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
$ python3 msrandomizer.py goodmorning goodafternoon goodnight
</code></pre> 

The result:
<pre><code class="language-python">
Namespace(sources=['goodmorning', 'goodafternoon'], dest=['goodnight'], kits=25)
</code></pre> 

Perfect! We can access these values using dot notation (e.g. `args.sources`)

---

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
                print(f'{copied_string:&lt;50}{"":&lt;10}{cumulative_size_string:&lt;}'  )

                samples_added += 1

            else:
                attempts +=1


        current_kit_label = current_kit_label + 1
</code></pre> 

> **Note**
> After actually using my script "in production", I noticed some kits were missing samples. The issue was that some samples I was using started with dots(designating them as hidden) and others (less seriously) with non-numeric characters(impacting legibility). To fix this, import `re` for [regular expression](https://en.wikipedia.org/wiki/Regular_expression) matching, and add the following method:
> <pre><code class="language-python"> 
>     def remove_leading_non_alphanumeric(input_string):
>     return re.sub(r'^[^a-zA-Z0-9]*', '', input_string)
> </code></pre>
>
> Do some manuvering to rename the file when copying it:
<pre><code class="language-python"> 
     # Pick random file
            files = [os.path.join(path, filename)
                for path, dirs, files in os.walk(source)
                for filename in files]
            random_file_path = random.choice(files)

            # Only grab audio files
            if (os.path.isfile(random_file_path) and 
                random_file_path.lower().endswith(('.wav', '.mp3', '.aiff'))):

                renamed_file_basename = remove_leading_non_alphanumeric_characters(os.path.basename(random_file_path))
                renamed_file_path = os.path.join(output_folder, renamed_file_basename)
                shutil.copy(random_file_path, os.path.join(output_folder, renamed_file_basename))

                copied_string = random_file_path + ' copied to ' + kit_folder

> </code></pre>


And that's it! The complete & final code can be found [here](https://github.com/eldun/msrandomizer/blob/main/msrandomizer.py).

---

### Results
Check back in a couple days and I'll have made some preposturous beats with my ultra-fresh random kits.

---

### Bonus AI Test
I'm a litte late to the party - I haven't tried using [ChatGPT3](https://openai.com/blog/chatgpt) yet! Can it generate a comparable script in minutes?

> **Note**
> I generated the following script before I realized the issue with hidden files. I'm sure ChatGPT would be up to the task, but I don't feel like going through any more iterations.

...

Holy COW. I knew chat GPT was impressive, but using it to generate solutions for my personal projects feels otherworldly. After a few iterations and clarifications, this was my request:

<pre><code class="language-terminal" style="white-space:pre-line">Generate a python script that accepts the following arguments in the following order: 'source', 'destination', and 'num_folders'. The user should be able to specify more than one source directory. The arguments should be parsed using argparse. 

The script should create num_folders folders(named sequentially in hex) at the destination path with 6 unique audio files in each folder. Each of the 6 unique audio files should be randomly selected and copied from a random selection of the source directories and its sub-directories. If fewer than 6 unique audio files are found, notify the user, remove any folders and files that have been created, and exit the program. 

Keep track of the cumulative size 'cumulative_size' of the files that have been copied. If cumulative_size is about to exceed 1 GiB, notify the user, delete the most recently created hex folder and files, leave the others, and exit the program.  When copying a file, print(in vertically-aligned columns) the last 40 characters of the relative path of the file being copied, the folder it's being copied to, and cumulative_size (labeled 'MiB copied so far').</code></pre> 

The result might look a bit familiar:

<pre><code class="language-python">import os
import shutil
import random
import argparse

MAX_SIZE = 1024 ** 3  # 1 GiB in bytes


def main():
    parser = argparse.ArgumentParser(description='Copy random audio files to folders.')    
    parser.add_argument('sources', nargs='+', help='the source folder(s) to select audio files from')
    parser.add_argument('destination', help='the destination folder to create sub-folders in')
    parser.add_argument('num_folders', type=int, help='the number of folders to create')
    args = parser.parse_args()

    # create destination folder if it doesn't exist
    os.makedirs(args.destination, exist_ok=True)

    cumulative_size = 0
    for i in range(args.num_folders):
        folder_name = hex(i)[2:].zfill(2)  # convert to hex and zero-pad to 2 digits
        folder_path = os.path.join(args.destination, folder_name)
        os.mkdir(folder_path)

        files = []
        for source in args.sources:
            for root, _, filenames in os.walk(source):
                for filename in filenames:
                    if filename.endswith('.mp3') or filename.endswith('.wav'):
                        files.append(os.path.join(root, filename))

        if len(files) < 6:
            print(f"Not enough audio files found for folder {folder_name}.")
            shutil.rmtree(folder_path)
            break

        folder_size = 0
        selected_files = random.sample(files, 6)
        for file_path in selected_files:
            file_size = os.path.getsize(file_path)
            if cumulative_size + folder_size + file_size > MAX_SIZE:
                print(f"Folder {folder_name} exceeds 1 GiB. Deleting folder.")
                shutil.rmtree(folder_path)
                return

            relative_path = os.path.relpath(file_path, args.sources[0])[-40:]
            dest_path = os.path.join(folder_path, os.path.basename(file_path))
            shutil.copy2(file_path, dest_path)
            folder_size += file_size
            cumulative_size += file_size

            print(f"{relative_path:40} {folder_name} {cumulative_size / (1024 ** 2):10.2f} MiB copied so far.")

if __name__ == '__main__':
    main()
</code></pre> 

The only thing I changed was the order of the arguments.

Thanks for reading - see you next time!

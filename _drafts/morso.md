---
title: Morso
subtitle: Creating a Morse Code Android Application with Kotlin
excerpt: I need to learn Morse code if I want to be able to communicate with all my **really** cool neighbors.
reason: To learn Kotlin, start (& finish) an Android app, and create a convenient way to practice Morse.
disclaimer:
toc: true
use-math: true
use-raw-images: false 
layout: post
author: Evan
header-image: /assets\images\blog-images\morso\telegraph.jpg 
header-image-alt:
header-image-title: "An old telegraph! Source: https://www.history.com/topics/inventions/telegraph"
tags: android kotlin
---

## Why Morse Code?
One of my least favorite things in this world is having to yell in someone's ear. Usually, I don't have to. Occasionally, though, I find myself at a bar.

One of my favorite things in this world is the process of getting better (at anything!). Rather than spending hours learning [American Sign Language](https://en.wikipedia.org/wiki/American_Sign_Language) (which **is** on my to-do list), I could just learn 26 characters in [Morse code](https://en.wikipedia.org/wiki/Morse_code) and tap out a message on my friend's shoulder!

I already learned the [Dvorak keyboard layout](https://en.wikipedia.org/wiki/Dvorak_keyboard_layout) (not reccomended) - which is unsurprisingly pretty similar to the structure of Morse code (look at the home row)! Obviously, the most used letters are the most accessible.

[Dvorak layout](assets\images\blog-images\morso\dvorak-layout.png)
[Morse code structure]()

Additionally, the scope of this project seems perfect for getting back into Android development and learning Kotlin.

## The General Idea
I believe the best way to learn is by doing, which is why I want to create a custom Morse keyboard. Android has a useful "language/input" button for switching the keyboard quickly:
![Android keyboard button](assets\images\blog-images\morso\keyboard-button.png)

Practice utilities can be found within the application. Some ideas I've had are as follows:
- Reading/Typing Morse
- Reading Morse through vibration/sound/flashing
- Time Trials

Morso will be written in [Kotlin](https://developer.android.com/kotlin/first), Android's "offical" language.

# The First Step
The most obvious first step to me is to create an "input method" that can be used system-wide. The [Android Developer article on input methods](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method) and [this StackOverflow answer](https://stackoverflow.com/a/44939816) will be exceedingly helpful.

1. Create a layout file in `res/layout`
    Here, we create a container for our "keyboard" which we'll design later.

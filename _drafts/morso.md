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

I already learned the [Dvorak keyboard layout](https://en.wikipedia.org/wiki/Dvorak_keyboard_layout) (not recommended) - which is unsurprisingly pretty similar to the structure of Morse code (look at the home row)! Obviously, the most used letters are the most accessible.

[Dvorak layout](assets\images\blog-images\morso\dvorak-layout.png)
[Morse code structure]()

Additionally, the scope of this project seems perfect for getting back into Android development and learning Kotlin.

## The General Idea
I believe the best way to learn is by doing, which is why I want to create a custom Morse keyboard. Android has a useful "language/input" button for switching the keyboard quickly:
![Android keyboard button](assets\images\blog-images\morso\keyboard-button.png)

Keep in mind that I'm not trying to reinvent the keyboard here - just creating a handy, accessible practice tool. For that reason, I'll be structuring my application in much the same way that GBoard does - a keyboard with some settings and utilities accessible from the top row.

Some practice ideas I've had are as follows:

- Reading/Typing Morse
- Reading Morse through vibration/sound/flashing
- Time Trials

Morso will be written in [Kotlin](https://developer.android.com/kotlin/first), Android's "official" language.

## The First Step
The most obvious first step to me is to create an input service that can be used system-wide. The [Android Developer article on input methods](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method) and [this StackOverflow answer](https://stackoverflow.com/a/44939816) will be exceedingly helpful.

### 1. Declare the Input in the Manifest
Official documentation for this step can be found [here](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method#DefiningIME), but we're basically going to throw this snippet into our app's [`AndroidManifest.xml`](https://developer.android.com/guide/topics/manifest/manifest-intro):

```xml
<!-- Declares the input method service -->
<service android:name="MorsoIME"
    android:label="@string/morso_label"
    android:permission="android.permission.BIND_INPUT_METHOD">
    <intent-filter>
        <action android:name="android.view.InputMethod" />
    </intent-filter>
    <meta-data android:name="android.view.im"
               android:resource="@xml/method" />
</service>
```

I was notified of an error about how `android:exported` must be set to `true` or `false` - I set it to true. You can read about the exported attribute [here](https://developer.android.com/guide/topics/manifest/service-element#exported)

My complete `AndroidManifest.xml` looks like this (I have no activities, as you can see.):

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="net.eldun.morso">

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.Morso" />

    <!-- Declares the input method service -->
    <service android:name="MorsoIME"
        android:label="@string/morso_label"
        android:permission="android.permission.BIND_INPUT_METHOD"
        android:exported="true">
        <intent-filter>
            <action android:name="android.view.InputMethod" />
        </intent-filter>
        <meta-data android:name="android.view.im"
            android:resource="@xml/method" />
    </service>

</manifest>
```

I was also warned that the `android.preference` library is deprecated when I created the `xml/method` file. I added this line to my `build.gradle` (Module: app):

```gradle
dependencies {
    ...
    implementation "androidx.preference:preference:1.1.0"
    ...
}
```

[Source](https://stackoverflow.com/a/56833739)

### 2. Declare the Settings Activity for the IME

> This next snippet declares the settings activity for the IME. It has an intent filter for ACTION_MAIN that indicates this activity is the main entry point for the IME application:

<!-- Optional: an activity for controlling the IME settings -->
<activity android:name="MorsoIMESettings"
    android:label="@string/morso_settings">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
    </intent-filter>
</activity>

I don't plan on using this snippet - the official docs even say what I was thinking:

> You can also provide access to the IME's settings directly from its UI.


### 3. Create our MorsoIME Class
You may have noticed that we have a warning that a service by the name of `MorsoIME` could not be found! Go ahead and create a new Kotlin class - `MorsoIME` - that extends `InputMethodService`:

> The central part of an IME is a service component, a class that extends [`InputMethodService`](https://developer.android.com/reference/android/inputmethodservice/InputMethodService). In addition to implementing the normal [service lifecycle](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method#InputMethodLifecycle), this class has callbacks for providing your IME's UI, handling user input, and delivering text to the field that currently has focus. By default, the `InputMethodService` class provides most of the implementation for managing the state and visibility of the IME and communicating with the current input field.

By overriding the `onCreateInputView()` callback, we can specify a layout file to inflate. This is what our placeholder `MorsoIME` looks like - the layout files will still need to be created:

```kotlin
class MorsoIME : InputMethodService() {

    override fun onCreateInputView(): View {
        return layoutInflater.inflate(R.layout.input, null).apply {
            if (this is MorsoView) {
                setOnKeyboardActionListener(this)
//                keyboard = latinKeyboard
            }
        }
    }

    private fun setOnKeyboardActionListener(action : MorsoIME) {

    }

}
```

### 3. Create our Input View
Go ahead and create a new XML file `input` at `res/layout`:



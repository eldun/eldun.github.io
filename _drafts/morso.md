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

[Dvorak layout](/assets/images/blog-images/morso/dvorak-layout.png)

<span class="row">
[Morse code structure](/assets/images/blog-images/morso/morse-code-tree.png)
[Morse code chart](/assets/images/blog-images/morso/morse-code-chart.png)
</span>

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
The most obvious first step to me is to create an input [service](https://developer.android.com/reference/android/app/Service) that can be used system-wide. The [Android Developer article on input methods](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method) and [this StackOverflow answer](https://stackoverflow.com/a/44939816) will be exceedingly helpful.

### 1. Declare IME Components in the Manifest
Official documentation for this step can be found [here](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method#DefiningIME), but we're basically going to throw a snippet into our app's [`AndroidManifest.xml`](https://developer.android.com/guide/topics/manifest/manifest-intro).

> The following snippet declares an IME service. It requests the permission BIND_INPUT_METHOD to allow the service to connect the IME to the system, sets up an intent filter that matches the action android.view.InputMethod, and defines metadata for the IME:

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

I was notified of an error about how `android:exported` must be set to `true` or `false` - I set it to true. You can read about the exported attribute [here](https://developer.android.com/guide/topics/manifest/service-element#exported).

I was also warned that the `android.preference` library is deprecated when I created the `xml/method` file. I added this line to my `build.gradle` (Module: app):

```gradle
dependencies {
    ...
    implementation "androidx.preference:preference:1.1.0"
    ...
}
```

[Source](https://stackoverflow.com/a/56833739)

Another issue I was having was that I was unable to select Morso as an input method. The reason why was that I had not yet added any [subtypes](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method#IMESubTypes) to `res/xml/method.xml`. For now, you can paste this minimal example into `res/xml/method.xml`:

```kotlin
<?xml version="1.0" encoding="utf-8"?>
<input-method
    xmlns:android="http://schemas.android.com/apk/res/android">

    <subtype
        android:imeSubtypeMode="keyboard"/>

</input-method>
```

We will cover subtypes in further detail later on.


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


This is what our placeholder `MorsoIME` looks like (we'll create our UI in the next section):

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
If you're slightly confused by that `apply` block, read about Kotlin's [scope functions](https://kotlinlang.org/docs/scope-functions.html) and [higher-order functions](https://kotlinlang.org/docs/lambdas.html). 

### 3. Create our Input View
We have two options for [designing our UI](https://developer.android.com/develop/ui) - the traditional "Views" method, and the newer "Jetpack Compose" method. We'll go through both for completeness, starting...

#### With "Views"
Everything you could want to know about views can be found [here](https://developer.android.com/guide/topics/ui/how-android-draws), [here](https://developer.android.com/develop/ui/views/layout/declaring-layout), [here](https://developer.android.com/develop/ui/views/layout/custom-views/custom-components), and [here](https://developer.android.com/codelabs/advanced-android-kotlin-training-custom-views#0).

![A typical view hierarchy](/assets/images/blog-images/morso/android-layout.png)

##### Creating a Placeholder Layout
Create `res/input.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <ImageView
        android:id="@+id/morsoView"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        app:srcCompat="@drawable/ic_launcher_background"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
```
![Placeholder View](/assets/images/blog-images/morso/android-placeholder.png)

Note that setting the `ImageView` dimensions to `0dp` is equivalent to `match_constraint`.

Once we create our custom `MorsoView` class, we'll replace the `<ImageView>` tag with `<net.eldun.morso.MorsoView>`.






##### Creating our Custom MorsoView

1. Create a new Kotlin class called MorsoView.
2. Modify the class definition to extend View.
3. Click on View and then click the red bulb. Choose Add Android View constructors using ‘@JvmOverloads'. Android Studio adds the constructor from the View class. The @JvmOverloads annotation instructs the Kotlin compiler to generate overloads for this function that substitute default parameter values.

```kotlin
package net.eldun.morso

import android.content.Context
import android.util.AttributeSet
import android.view.View

class MorsoView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {
    
}
```

Now let's follow the steps necessary to [draw a custom view](https://developer.android.com/codelabs/advanced-android-kotlin-training-custom-views#4). How about we start with a black rectangle with "Morso" in the center?

We could do both of these tasks in XML by extending a `Button` view (rather than a generic `View`) and using the `background` and `buttonText` attributes - or by [Defining Custom Attributes](https://developer.android.com/develop/ui/views/layout/custom-views/create-view#customattr) for our totally custom view. I don't have a great reason for setting properties programmatically, other than the fact that it's fast.




##### Overriding `onSizeChanged()`

First, we'll override the `onSizeChanged()` -
> The onSizeChanged() method is called any time the view's size changes, including the first time it is drawn when the layout is inflated. Override onSizeChanged() to calculate positions, dimensions, and any other values related to your custom view's size, instead of recalculating them every time you draw.

Add member floats `centerX` and `centerY` to our `MorsoView` class, and then calculate them in `onSizeChanged`

```kotlin
override fun onSizeChanged(width: Int, height: Int, oldWidth: Int, oldHeight: Int) {
   centerX = (width / 2.0).toFloat()
   centerY = (height / 2.0).toFloat()
}
```

This won't *exactly* center the text (there's a lot going on with fonts!) - it's only a placeholder. If you wish you can add the code to [actually center it](https://stackoverflow.com/a/32081250).


##### Creating a `Paint` Object for Drawing Text
We're going to need a `Paint` object for drawing text:

```kotlin
class MorsoView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View (context, attrs, defStyleAttr) {

+    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
+        // Paint styles used for rendering are initialized here. This
+        // is a performance optimization, since onDraw() is called
+        // for every screen refresh.
+        style = Paint.Style.FILL
+        textAlign = Paint.Align.CENTER
+        textSize = 55.0f
+    }

    private var centerX = 100F
    private var centerY = 100F
```
##### Drawing our View
Next, we'll draw our view by overriding `onDraw()` (we'll also set the background color here):

```kotlin
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        this.setBackgroundColor(Color.BLACK)
        canvas.drawText("Morso", centerX, centerY, paint)
    }
```

If you take a look at our generated layout, you'll notice `MorsoView` takes up almost the whole screen. While this might be useful for typing without looking, it's definitely not a reasonable default.

In order to determine how much space MorsoView is alloted, we'll have to override `onMeasure()`. Two helpful snippets about `onMeasure()` can be found [here](https://developer.android.com/develop/ui/views/layout/custom-views/custom-components#extend-ondraw-and-onmeasure) and [here](https://developer.android.com/develop/ui/views/layout/custom-views/custom-drawing#layouteevent).

From the second link:
> `onMeasure`'s parameters are View.MeasureSpec values that tell you how big your view's parent wants your view to be, and whether that size is a hard maximum or just a suggestion. As an optimization, these values are stored as packed integers, and you use the static methods of `View.MeasureSpec` to unpack the information stored in each integer.

This StackOverflow answer has a nice description of the different `MeasureSpec`s and how they relate to the width and height we set in our `res/input.xml`

Add a helper function to get the screen height:
```kotlin
    fun getScreenHeight(): Int {
        return Resources.getSystem().getDisplayMetrics().heightPixels
    }
```

Now we can override `MorsoView`'s `onMeasure()` and set the height to a quarter of the screen height:

```kotlin
override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val desiredWidth = 100;
        val desiredHeight = getScreenHeight() / 4;

        val widthMode = MeasureSpec.getMode(widthMeasureSpec);
        val widthSize = MeasureSpec.getSize(widthMeasureSpec);
        val heightMode = MeasureSpec.getMode(heightMeasureSpec);
        val heightSize = MeasureSpec.getSize(heightMeasureSpec);

        var width : Int;
        var height : Int;

        //Measure Width
        when (widthMode) {
            MeasureSpec.EXACTLY -> width = widthSize;
            MeasureSpec.AT_MOST -> width = Math.min(desiredWidth, widthSize);
            else -> width = desiredWidth;
        }

        // Measure Height
        when (heightMode) {
            MeasureSpec.EXACTLY -> height = heightSize;
            MeasureSpec.AT_MOST -> height = Math.min(desiredHeight, heightSize);
            else -> height = desiredHeight;
        }

        //MUST CALL THIS
        setMeasuredDimension(width, height);
    }

```

![Morso measured view](/assets/images/blog-images/morso/morso-measured-view.png)

<!-- OK, I think that gives us a rough idea of what it's like to work with the traditional view method. -->


<!-- #### With "Jetpack Compose"
-- Right off the bat, the fact that we're using an `InputMethodService` instead of an `Activity` or `Fragment` makes following the [Compose tutorial](https://developer.android.com/jetpack/compose/tutorial) a little more challenging. Thankfully, [somebody else has gone through this same issue](https://stackoverflow.com/a/66958772) --


### Starting our IME Service
When  -->

##### Making our View Interactive
The article for this section can be found [here](https://developer.android.com/develop/ui/views/layout/custom-views/making-interactive).


> Like many other UI frameworks, Android supports an input event model. User actions are turned into events that trigger callbacks, and you can override the callbacks to customize how your application responds to the user. The most common input event in the Android system is touch, which triggers onTouchEvent(android.view.MotionEvent).
>
> Touch events by themselves are not particularly useful. Modern touch UIs define interactions in terms of gestures such as tapping, pulling, pushing, flinging, and zooming. To convert raw touch events into gestures, Android provides GestureDetector.

The obvious gestures that we're going to be looking for are taps(dots) and holds(dashes). Eventually, we might want to listen for swipes to signal the end of a string or to switch to numerical input.

To learn more about gestures, go [here](https://developer.android.com/develop/ui/views/touch-and-input/gestures).

> If you only want to process a few gestures, you can extend `GestureDetector.SimpleOnGestureListener` instead of implementing the `GestureDetector.OnGestureListener` interface.

Create a new `MorsoGestureListener` class that extends `SimpleGestureListener`:

```kotlin
package net.eldun.morso

import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent

class MorsoGestureListener : GestureDetector.SimpleOnGestureListener() {

    val TAG = "MorsoGestureListener"

    override fun onDown(e: MotionEvent): Boolean {
        Log.i(TAG, "downMotion detected!")

        return true
    }

    override fun onSingleTapUp(e: MotionEvent): Boolean {
        Log.i(TAG, "tap detected!")
        return true
    }

}
```

> Whether or not you use GestureDetector.SimpleOnGestureListener, you must always implement an onDown() method that returns true. This step is necessary because all gestures begin with an onDown() message. If you return false from onDown(), as GestureDetector.SimpleOnGestureListener does, the system assumes that you want to ignore the rest of the gesture, and the other methods of GestureDetector.OnGestureListener never get called. The only time you should return false from onDown() is if you truly want to ignore an entire gesture. Once you've implemented GestureDetector.OnGestureListener and created an instance of GestureDetector, you can use your GestureDetector to interpret the touch events you receive in onTouchEvent().

In our MorsoView, add the following (along with any necessary imports):

```kotlin
class MorsoView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View (context, attrs, defStyleAttr) {

    val TAG = "MorsoView"

+    private val gestureListener =  MorsoGestureListener()
+    private val gestureDetector = GestureDetector(context, gestureListener)


    // ...
    // code
    // ...


+    override fun onTouchEvent(event: MotionEvent): Boolean {
+        return gestureDetector.onTouchEvent(event)
+    }

}
```

> When you pass onTouchEvent() a touch event that it doesn't recognize as part of a gesture, it returns false. You can then run your own custom gesture-detection code.

This is where we can implement gestures like triple taps in the future.



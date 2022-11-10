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

...

Thinking about it some more, we're probably going to end up creating all of our own gestures from within MorsoView's on `onTouchEvent`. In doing so, we'll be able to specify custom timing delays for dots and dashes and the like. However, it's good for now.

Let's put things in place replace the "Morso" text on touch inputs with the appropriate characters.

##### Learning About Representing UI State
The main article for this section is [here](https://developer.android.com/topic/architecture/ui-layer#define-ui-state). I suggest reading it.

Details on how IMEs handle config changes can be found [here](https://developer.android.com/reference/android/inputmethodservice/InputMethodService#onConfigurationChanged(android.content.res.Configuration)).

<!-- Long story short, we're going to use [ViewModels](https://developer.android.com/topic/libraries/architecture/viewmodel). If you already know the story with ViewModels, you can skip to [the next section]({{ post.url }}/drawing-symbols-on-input) -->






<!-- We'll be using a [data class](https://kotlinlang.org/docs/data-classes.html) to represent the UI state. It's not much at the moment:

```kotlin
package net.eldun.morso

data class MorsoViewState(){
    val mainText : String
}
``` -->

Here's an explanation for why the UI state member(s) are [immutable](https://kotlinlang.org/docs/basic-syntax.html#variables):

```kotlin
data class NewsUiState(
    val isSignedIn: Boolean = false,
    val isPremium: Boolean = false,
    val newsItems: List<NewsItemUiState> = listOf(),
    val userMessages: List<Message> = listOf()
)

data class NewsItemUiState(
    val title: String,
    val body: String,
    val bookmarked: Boolean = false,
    ...
)
```
> The UI state definition in the example above is immutable. The key benefit of this is that immutable objects provide guarantees regarding the state of the application at an instant in time. This frees up the UI to focus on a single role: to read the state and update its UI elements accordingly. As a result, you should never modify the UI state in the UI directly unless the UI itself is the sole source of its data. Violating this principle results in multiple sources of truth for the same piece of information, leading to data inconsistencies and subtle bugs.
>
> For example, if the bookmarked flag in a NewsItemUiState object from the UI state in the case study were updated in the Activity class, that flag would be competing with the data layer as the source of the bookmarked status of an article. Immutable data classes are very useful for preventing this kind of antipattern.
>
> Key Point: Only sources or owners of data should be responsible for updating the data they expose.

Great. You might be wondering - as I was - "How does anything ever change, then?"

The answer is by using a mediator to process events and produce the UI state.

> Interactions and their logic may be housed in the UI itself, but this can quickly get unwieldy as the UI starts to become more than its name suggests: it becomes data owner, producer, transformer, and more. Furthermore, this can affect testability because the resulting code is a tightly coupled amalgam with no discernable boundaries. Unless the UI state is very simple, the UI's sole responsibility should be to consume and display UI state.

> The classes that are responsible for the production of UI state and contain the necessary logic for that task are called [state holders](https://developer.android.com/topic/architecture/ui-layer#state-holders).

> Key Point: The [ViewModel](https://developer.android.com/topic/libraries/architecture/viewmodel) type is the recommended implementation for the management of screen-level UI state with access to the data layer. Furthermore, it survives configuration changes (like rotations) automatically. ViewModel classes define the logic to be applied to events in the app and produce updated state as a result.




> There are many ways to model the codependency between the UI and its state producer. However, because the interaction between the UI and its ViewModel class can largely be understood as event input and its ensuing state output, the relationship can be represented as shown in the following diagram illustrating the "Unidirectional Data Flow" pattern:

![Unidirectional Data Flow](/assets/images/blog-images/morso/udf.png)

- The ViewModel holds and exposes the state to be consumed by the UI. The UI state is application data transformed by the ViewModel.
- The UI notifies the ViewModel of user events.
- The ViewModel handles the user actions and updates the state.
- The updated state is fed back to the UI to render.
- The above is repeated for any event that causes a mutation of state.

[Why use UDF?](https://developer.android.com/topic/architecture/ui-layer#why-use-udf)

Here's an rudimentary example of what would happen if a user were to bookmark an article in a simple news app:

![Unidirectional Data Flow Example](/assets/images/blog-images/morso/udf-example.png)

<!-- ##### Creating and Storing our UI State Class with ViewModel
For this section, we'll mostly be looking at the [Android article on `ViewModel`](https://developer.android.com/reference/androidx/lifecycle/ViewModel) and the [ViewModel Codelab](https://developer.android.com/codelabs/basic-android-kotlin-training-viewmodel#0). Neither of these resources mention services or IME's (only activities and fragments), but I don't see any reason not to use ViewModels.

Our first implementation of our `ViewModel` class will merely hold the value of what is displayed in `MorsoIME` - which happens to be `MorsoView`. Further down the line, we may end up with more views - in which case we could add to `MorsoViewModel` *or* create new viewmodels for each view to avoid a monolithic `MorsoViewModel`. "Why is the `ViewModel` assosciated with the service and not the view?" you might ask. The reason is that the viewmodel is tied to the lifecycle of the activity/fragment/service. Also - the view should retain no data about state - merely display it.

![Default MorsoView](/assets/images/blog-images/morso/morso-measured-view.png)

With that being said, let's create `MorsoViewModel`:

```kotlin
package net.eldun.morso

import androidx.lifecycle.ViewModel

class MorsoViewModel : ViewModel() {
}
```

Now we have to assosciate our `ViewModel` with our IME - we'll add a member of type `MorsoViewModel` to `MorsoIME` and initialize it using the `by viewModels()` property delegate:

```kotlin
private val viewModel: MorsoViewModel by viewModels()
}
 ``` -->

<!-- ###### What are Property Delegates?

> In Kotlin, each mutable (var) property has default getter and setter functions automatically generated for it. The setter and getter functions are called when you assign a value or read the value of the property.
> 
> For a read-only property (val), it differs slightly from a mutable property. Only the getter function is generated by default. This getter function is called when you read the value of a read-only property.
> 
> Property delegation in Kotlin helps you to handoff the getter-setter responsibility to a different class.
> 
> This class (called delegate class) provides getter and setter functions of the property and handles its changes.
> 
> A delegate property is defined using the by clause and a delegate class instance:
> 
> 
> // Syntax for property delegation
> var <property-name> : <property-type> by <delegate-class>()
> In your app, if you initialize the view model using default GameViewModel constructor, like below:
> 
> 
> private val viewModel = GameViewModel()
> Then the app will lose the state of the viewModel reference when the device goes through a configuration change. For example, if you rotate the device, then the activity is destroyed and created again, and you'll have a new view model instance with the initial state again.
> 
> Instead, use the property delegate approach and delegate the responsibility of the viewModel object to a separate class called viewModels. That means when you access the viewModel object, it is handled internally by the delegate class, viewModels. The delegate class creates the viewModel object for you on the first access, and retains its value through configuration changes and returns the value when requested. -->

<!-- ###### Adding Data to our ViewModel
The article for this section can be found [here](https://developer.android.com/codelabs/basic-android-kotlin-training-viewmodel#4)

Right now, the only property in our `MorsoViewModel` is the the background text:
```kotlin
    private var backgroundText = "Morso"
```

However,

> Inside the ViewModel, the data should be editable, so they should be private and var. From outside the ViewModel, data should be readable, but not editable, so the data should be exposed as public and val. To achieve this behavior, Kotlin has a feature called a [backing property](https://kotlinlang.org/docs/properties.html#backing-properties).

```
class MorsoViewModel : ViewModel() {

    private var _backgroundText = "Morso"
    val backgroundText: String
        get() = _backgroundText()
}
```

Mutable data fields from the viewmodel should **never** be exposed. -->



##### Storing UI Data for our Input Service
As it turns out, we don't actually have to use viewmodels, because `InputServiceMethod`s generally [don't have to worry about configuration changes](https://developer.android.com/reference/android/inputmethodservice/InputMethodService#onConfigurationChanged(android.content.res.Configuration)) - which is the main reason to use viewmodels (other than the seperation of ui from state, of course). As is often the case when traveling a bit off the beaten path, the [answers are not always *totally* crystal clear](https://github.com/android/architecture-components-samples/issues/137#issuecomment-327854042), though. Based on what I've read, it sounds like we can get away with a mere [plain class for state holding](https://developer.android.com/topic/architecture/ui-layer/stateholders#choose_between_a_viewmodel_and_plain_class_for_a_state_holder).

The following info is from [this codelab](https://developer.android.com/codelabs/basic-android-kotlin-training-viewmodel#4). Even though the codelab is about viewmodels, the same principles still apply to our plain state class.

Create `MorsoUiState`:

Right now, the only property in our `MorsoUiState` is the the background text:
```kotlin
    private var backgroundText = "Morso"
```

However,

> Inside the ViewModel, the data should be editable, so they should be private and var. From outside the ViewModel, data should be readable, but not editable, so the data should be exposed as public and val. To achieve this behavior, Kotlin has a feature called a [backing property](https://kotlinlang.org/docs/properties.html#backing-properties).

```
class MorsoUiState {

    private var _backgroundText = "Morso"
    val backgroundText: String
        get() = _backgroundText()

    fun setBackgroundText(input: String) {
        _backgroundText = input
    }
}
```

Mutable data fields from state holders should **never** be exposed.

##### Updating our View with New UI Data

<!-- The main article for this section can be found [here](https://developer.android.com/topic/libraries/data-binding/architecture). -->

We can automatically update our UI using [LiveData](https://developer.android.com/topic/libraries/architecture/livedata) as the binding source.

First, we should update `MorsoView` with a function to update all of its fields(which should all be private):
```kotlin
...

    private var backgroundText = "Morso"


    fun updateUi(morsoUiState: MorsoUiState) {
        backgroundText = morsoUiState.backgroundText.value.toString()

    }
...
```

To [work with LiveData](https://developer.android.com/topic/libraries/architecture/livedata#work_livedata), we must follow these steps:

1. [Create an instance of LiveData](https://developer.android.com/topic/libraries/architecture/livedata#create_livedata_objects) to hold a certain type of data. This is usually done within your ViewModel class.

```kotlin
class MorsoUiState {

    val backgroundText: MutableLiveData<String> by lazy {
        MutableLiveData<String>("Morso")
    }
}
```

2. Create an Observer object that defines the onChanged() method, which controls what happens when the LiveData object's held data changes. You usually create an Observer object in a UI controller, such as an activity or fragment.

```kotlin
class MorsoIME : InputMethodService() {
    private val TAG = "MorsoIME"


    override fun onCreateInputView(): View {
    val morsoLayout = layoutInflater.inflate(R.layout.input_container, null)
        morsoView = morsoLayout.findViewById<MorsoView>(R.id.morsoView)

        // Create the observer which updates the UI.
        val backgroundTextObserver = Observer<String> {

            // Update the UI
            morsoView.updateUi(morsoUiState)
            morsoView.invalidate()
        }

        return morsoLayout
    }

}
```

3. Attach the Observer object to the LiveData object using the observe() method. The observe() method takes a LifecycleOwner object. This subscribes the Observer object to the LiveData object so that it is notified of changes. You usually attach the Observer object in a UI controller, such as an activity or fragment.

> You can register an observer without an associated LifecycleOwner object using the observeForever(Observer) method. In this case, the observer is considered to be always active and is therefore always notified about modifications. You can remove these observers calling the removeObserver(Observer) method.

```kotlin
class MorsoIME : InputMethodService() {
    private val TAG = "MorsoIME"

    lateinit var morsoView: MorsoView
    lateinit var morsoGestureListener : MorsoGestureListener
    lateinit var morsoUiState: MorsoUiState


    override fun onCreateInputView(): View {

        val morsoLayout = layoutInflater.inflate(R.layout.input_container, null)
        morsoView = morsoLayout.findViewById<MorsoView>(R.id.morsoView)
        morsoGestureListener = morsoView.gestureListener
        morsoUiState = morsoGestureListener.morsoUiState


        // Create the observer which updates the UI.
        val backgroundTextObserver = Observer<String> {
            
            // Update the UI
            morsoView.updateUi(morsoUiState)
            morsoView.invalidate()
        }

        // Observe the LiveData
        morsoUiState.backgroundText.observeForever(backgroundTextObserver)

        return morsoLayout
    }

}
```

When we have a more complex UI state, it might be worthwhile to make the whole `MorsoUiState` observable.

Add to `onSingleTapUp` in `MorsoGestureListener`:

```kotlin
   override fun onSingleTapUp(e: MotionEvent): Boolean {
+        morsoUiState.backgroundText.value = "tapped"
        return true
    }
```

Our "Morso" text will change to "tapped" on a single tap.

##### Resetting our Background Text After a Delay
Add the following code to the `backgroundTextObserver`:

```kotlin
// Create the observer which updates the UI.
        val backgroundTextObserver = Observer<String> { newBackgroundText ->
            Log.d(TAG, "onCreateInputView: New Text!")
            // Update the UI
            morsoView.backgroundText = newBackgroundText
            morsoView.invalidate()

+            if (morsoUiState.backgroundText.value != "Morso") {
+                Handler(Looper.getMainLooper()).postDelayed({
+                    morsoUiState.backgroundText.value = "Morso"
+                }, 1000)
            }
        }
```

We will be able to configure the delay in settings later on.

### Representing Morse Code


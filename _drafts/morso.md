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
As it turns out, we don't actually have to use viewmodels, because `InputServiceMethod`s [don't have to worry about configuration changes](https://developer.android.com/reference/android/inputmethodservice/InputMethodService#onConfigurationChanged(android.content.res.Configuration)) - which is the main reason to use viewmodels (other than the seperation of ui from state, of course). As is often the case when traveling a bit off the beaten path, the [answers are not always *totally* crystal clear](https://github.com/android/architecture-components-samples/issues/137#issuecomment-327854042), though. Based on what I've read, it sounds like we can get away with a mere [plain class for state holding](https://developer.android.com/topic/architecture/ui-layer/stateholders#choose_between_a_viewmodel_and_plain_class_for_a_state_holder). Furthermore, we'll make our UI state a [singleton](https://en.wikipedia.org/wiki/Singleton_pattern) by using the [object keyword](https://stackoverflow.com/questions/51834996/singleton-class-in-kotlin).

The following info is from [this codelab](https://developer.android.com/codelabs/basic-android-kotlin-training-viewmodel#4). Even though the codelab is about viewmodels, the same principles still apply to our plain state class.

Create `MorsoUiState`:

Right now, the only property in our `MorsoUiState` is the the background text:
```kotlin
    private var backgroundText = "Morso"
```

However,

> Inside the ViewModel, the data should be editable, so they should be private and var. From outside the ViewModel, data should be readable, but not editable, so the data should be exposed as public and val. To achieve this behavior, Kotlin has a feature called a [backing property](https://kotlinlang.org/docs/properties.html#backing-properties).

```
object MorsoUiState {

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

We're not using a viewmodel

```kotlin
object MorsoUiState {

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

I figure [enums](https://kotlinlang.org/docs/enum-classes.html#working-with-enum-constants) are a decent way to represent Morse code - we're dealing with a few dozen values that will never change.

Another option would be to use an immutable ordered binary tree created at compile-time in a companion object. If you use a tree, be aware that `Enum.compareTo()` is `final` - the order in which the enums are declared is important for comparing/navigating the tree. [Why is compareTo final?](https://stackoverflow.com/questions/519788/why-is-compareto-on-an-enum-final-in-java)

Lets represent signals in `MorseSignal`:
```kotlin
enum class MorseSignal {
    DOT, DASH, SPACE;
}
```

and characters in `Character`:
```kotlin
enum class Character(vararg var sequence: MorseSignal) {

    START(),

    E(DOT),
    T(DASH),

    I(DOT, DOT),
    A(DOT, DASH),
    N(DASH, DOT),
    M(DASH, DASH),

    S(DOT, DOT, DOT),
    U(DOT, DOT, DASH),
    R(DOT, DASH, DOT),
    W(DOT, DASH, DASH),
    D(DASH, DOT, DOT),
    K(DASH, DOT, DASH),
    G(DASH, DASH, DOT),
    O(DASH, DASH, DASH),

    H(DOT, DOT, DOT, DOT),
    V(DOT, DOT, DOT, DASH),
    F(DOT, DOT, DASH, DOT),
    L(DOT, DASH, DOT, DOT),
    P(DOT, DASH, DASH, DOT),
    J(DOT, DASH, DASH, DASH),
    B(DASH, DOT, DOT, DOT),
    X(DASH, DOT, DOT, DASH),
    C(DASH, DOT, DASH, DOT),
    Y(DASH, DOT, DASH, DASH),
    Z(DASH, DASH, DOT, DOT),
    Q(DASH, DASH, DOT, DASH),

    FIVE(DOT, DOT, DOT, DOT, DOT) {
        override fun toString() = "5"
    },
    FOUR(DOT, DOT, DOT, DOT, DASH){
        override fun toString() = "4"
    },
    THREE(DOT, DOT, DOT, DASH, DASH){
        override fun toString() = "3"
    },
    TWO(DOT, DOT, DASH, DASH, DASH){
        override fun toString() = "2"
    },
    PLUS_SIGN(DOT, DASH, DOT, DASH, DOT){
        override fun toString() = "+"
    },
    ONE(DOT, DASH, DASH, DASH, DASH){
        override fun toString() = "1"
    },
    SIX(DASH, DOT, DOT, DOT, DOT){
        override fun toString() = "6"
    },
    EQUALS_SIGN(DASH, DOT, DOT, DOT, DASH){
        override fun toString() = "="
    },
    DIVIDE_SIGN(DASH, DOT, DOT, DASH, DOT){
        override fun toString() = "/"
    },
    SEVEN(DASH, DASH, DOT, DOT, DOT){
        override fun toString() = "7"
    },
    EIGHT(DASH, DASH, DASH, DOT, DOT){
        override fun toString() = "8"
    },
    NINE(DASH, DASH, DASH, DASH, DOT){
        override fun toString() = "9"
    },
    ZERO(DASH, DASH, DASH, DASH, DASH){
        override fun toString() = "0"
    },
    NULL(){
        override fun toString() = ""
    };
}


```

We're going to want to be able to get the `Character` by its sequence once Morso detects a long enough break in input. To do so, we'll create a map with the key being `sequence` and the value being the `Character`.

I was originally trying to use the `vararg sequence`(which is an array) as a key, but in order to look up the value, the array passed in [had to be the exact same array as the key](https://stackoverflow.com/a/16839191) - not just the contents of the array. I ended up converting the sequence in `Character`'s construtor to a `List`, and using said list as a key for the dictionary:

```kotlin
    ...

    NINE(DASH, DASH, DASH, DASH, DOT){
        override fun toString() = "9"
    },
    ZERO(DASH, DASH, DASH, DASH, DASH){
        override fun toString() = "0"
    };

    private val sequenceList = this.sequence.asList()


    companion object {
        private val map = Character.values().associateBy(Character::sequenceList)
        fun fromSequenceList(seqList: List<MorseSignal>) = map[seqList]
    }
```

We can now pass in a list of signals to `fromSequenceList` to get the corresponding `Character`:
```kotlin
    class MorseTranslator {

        companion object {

            fun decode(vararg sequence: MorseSignal): Character? {

                return Character.fromSequenceList(sequence.asList())
            }
        }
    }
```

### Using Morso for Input

Now we can start to create an actual input method! Again, the most helpful article for this section can be found [here](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method).

My general idea for the default behavior of Morso is as follows:

- `MorsoInputView` will show the current input (dots and dashes) up until there's a word-length pause - at which point `MorsoInputView` will once again display 'Morso'.
- The current input field will reflect the input, but will only be committed upon a word-length pause.
- `MorsoInputView` will be updated to have a cancel button for the current sequence and a backspace.

MorsoCandidatesView will come later.

#### Translating Gestures to Morse Code
Taps are already handled in our `MorsoGestureListener`. However - it's a bit picky about what counts as a tap and doesn't register gestures like triple-taps. Additionally, we should allow the user to customize the dot time because the dash and space duration will be defined as multiples of the base dot time. 

Let's add to `MorsoGestureListener`:

```kotlin
    fun onHold(e: MotionEvent): Boolean {

        Log.d(TAG, "onHold")
        return true

    }
```

In `MorsoInputView`, add the following members:

```kotlin
    class MorsoInputView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View (context, attrs, defStyleAttr) {

    private val TAG = "MorsoView"

    val gestureListener =  MorsoGestureListener()
    private val gestureDetector = GestureDetector(context, gestureListener)
+    private var downTime: Long = 0
+    private var upTime: Long = 0
+    private val dotTime: Long = 300
+    private val dashTime = 3*dotTime
+    private val signalSpaceTimeout = dotTime
+    private val letterSpaceTimeout: Long = 3*dotTime
+    private val wordSpaceTimeout: Long = 7*dotTime



    ...
```

And add to `MorsoGestureListener`:

```kotlin
fun onShortPause(e: MotionEvent): Boolean {
        Log.d(TAG, "onShortPause")
        morsoUiState.reset()
        return true
    }

    fun onLongPause(e: MotionEvent): Boolean {
        Log.d(TAG, "onLongPause")
        inputConnection.commitText(" ", 1)

        return true
    }
```

 and then update `MorsoInputView`:

```kotlin

        override fun onTouchEvent(event: MotionEvent): Boolean {

        val onHoldRunnable = Runnable { gestureListener.onHold(event) }
        val shortPauseRunnable = Runnable { gestureListener.onShortPause(event) }
        val longPauseRunnable = Runnable { gestureListener.onLongPause(event) }


        if (event.actionMasked == MotionEvent.ACTION_DOWN) {
            downTime = SystemClock.elapsedRealtime()

            // Cancel possible pending runnables
            handler.removeCallbacksAndMessages(null)
            
            // Call onHold in dashTime ms
            handler.postDelayed(onHoldRunnable,dashTime)
        }




        else if (event.actionMasked == MotionEvent.ACTION_UP) {
            // Cancel the pending hold runnable and previous pause runnables
            handler.removeCallbacksAndMessages(null)

            upTime = SystemClock.elapsedRealtime()



            // Listen for all taps with no restrictions (slop, triple-taps, etc. - unlike our gesture detector)
            val elapsedTime = upTime - downTime
            if (elapsedTime < dotTime){
                gestureListener.onSingleTapUp(event)
            }


            // call timeouts if no input has been received
            handler.postDelayed(shortPauseRunnable, letterSpaceTimeout)
            handler.postDelayed(longPauseRunnable, wordSpaceTimeout)
            
            return true
        }
        
        // It's up to MorsoGestureListener to decide
        return gestureDetector.onTouchEvent(event)
    }
```




#### Implementing Candidates View
The [candidates view](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method#CandidateView) is something you're likely familiar with:

![Candidates View](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method#kotlin)

For Morso, I'd like to display the left child character, the current character (which can function as a countdown bar to the current character being committed), and the right child character in the candidates view. The rightmost suggestion can also double as a progress bar for dash inputs. One concern is that this is a *practice* application, so I'm not sure if I should make the suggestions clickable.

<span class="todo">Add progress bars to appropriate candidates</span>

First, we have to create a view `MorsoCandidateView`:

```kotlin
class MorsoCandidateView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : androidx.appcompat.widget.AppCompatButton (context, attrs, defStyleAttr) {

    private val TAG = "MorsoCandidatesView"

    init {
        setBackgroundColor(Color.DKGRAY)
        setTextColor(Color.WHITE)
        gravity = Gravity.CENTER
    }


}
```

Next, we have to create a layout `candidates.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/black">

    <net.eldun.morso.MorsoCandidateView
        android:id="@+id/morsoCandidateView"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:padding="10dp"
        android:text="left"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toStartOf="@+id/guideline3"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/guideline3"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        app:layout_constraintGuide_percent=".3333" />

    <net.eldun.morso.MorsoCandidateView
        android:id="@+id/morsoCandidateView2"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:padding="10dp"
        android:text="center"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toStartOf="@+id/guideline4"
        app:layout_constraintStart_toStartOf="@+id/guideline3"
        app:layout_constraintTop_toTopOf="parent" />

    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/guideline4"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        app:layout_constraintGuide_percent=".6667" />

    <net.eldun.morso.MorsoCandidateView
        android:id="@+id/morsoCandidateView3"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:padding="10dp"
        android:text="right"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="@+id/guideline4"
        app:layout_constraintTop_toTopOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
```

![Candidates layout](/assets/images/blog-images/morso/candidates-layout.png)



> [In the IME lifecycle, the system calls onCreateCandidatesView() when it's ready to display the candidates view. In your implementation of this method, return a layout that shows word suggestions, or return null if you don’t want to show anything.](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method#CandidateView)

> [To control when the candidates view is displayed, use setCandidatesViewShown(boolean). To change the candidates view after the first one is created by this function, use setCandidatesView(android.view.View).](https://developer.android.com/reference/android/inputmethodservice/InputMethodService#onCreateCandidatesView())

<span class="todo">I think that since this is a practice tool, it's alright to show the candidates view at all times. I can always add a setting to hide it later.</span>

 To display our new candidates layout, all we need to do is override `MorsoIME.onCreateCandidatesView()`:


```kotlin
    override fun onCreateCandidatesView(): View {
        Log.d(TAG, "onCreateCandidatesView")
        return layoutInflater.inflate(R.layout.candidates, null)
    }

```

and `setCandidatesViewShown(true)` from `MorsoIME.onCreateInputView()`.

![Morso candidates at runtime](/assets/images/blog-images/morso/morso-candidates-runtime.png)

##### Updating Candidates
> [To change the candidates view after the first one is created by setCandidatesViewShown(), use setCandidatesView(android.view.View).](https://developer.android.com/reference/android/inputmethodservice/InputMethodService#onCreateCandidatesView())

The default candidates will be "E", "", and "T", respectively (I overrode Character.START's `toString()` to return ""). We'll be using our Character enum class to look up candidates, similar to how we looked up values by a character's sequence earlier on:

```kotlin
    companion object {
        val TAG = "Character"

        private val sequenceMap = values().associateBy(Character::sequenceList)
+        private val stringMap = values().associateBy(Character::toString)
+
        fun fromSequenceList(seqList: List<MorseSignal>) = sequenceMap[seqList]
+        fun fromString(stringifiedCharacter: String) = stringMap[stringifiedCharacter]
+
```

Let's also add functions to retrieve the possible options from the current sequence:

```kotlin
fun getDotChild(character: Character): Character? {
            val result = fromSequenceList(character.sequenceList + DOT)
            if (result == null)
                return Character.NULL
            return result
        }


        fun getDashChild(character: Character): Character? {
            val result = fromSequenceList(character.sequenceList + DASH)
            if (result == null)
                return Character.NULL
            return result
        }
```

We can add our candidates to `MorsoUiState` now.

```kotlin
object MorsoUiState {

    val backgroundText: MutableLiveData<String> by lazy {
        MutableLiveData<String>("Morso")
    }

    // Default characters
    val currentCandidateText: MutableLiveData<String> by lazy {
            MutableLiveData<String>(Character.START.toString())
        }
    val dotCandidateText: MutableLiveData<String> by lazy {
        MutableLiveData<String>(Character.E.toString())
    }
    val dashCandidateText: MutableLiveData<String> by lazy {
        MutableLiveData<String>(Character.T.toString())
    }

    fun reset() {
        backgroundText.value = "Morso"
        currentCandidateText.value = Character.START.toString()
        dotCandidateText.value = Character.E.toString()
        dashCandidateText.value = Character.T.toString()
    }
}
```

We can update our `MorsoUiStateObserver` like so:

```kotlin
class MorsoUiStateObserver(val morso: MorsoIME, val uiState: MorsoUiState) {

    init {

        observeBackgroundText()
        observeCandidates()
    }

    private fun observeBackgroundText() {
        // Create the observer which updates the UI.
        val backgroundTextObserver = Observer<String> {

            morso.updateUi()

            if (uiState.backgroundText.value != "Morso") {
                Handler(Looper.getMainLooper()).postDelayed({
                    uiState.backgroundText.value = "Morso"
                }, 1000)
            }
        }

        // Observe the LiveData
        uiState.backgroundText.observeForever(backgroundTextObserver)
    }

    private fun observeCandidates() {

        // Create the observer which updates the UI.
        val candidatesTextObserver = Observer<String> {
            morso.updateUi()
        }

        // Observe the LiveData
        uiState.currentCandidateText.observeForever(candidatesTextObserver)
        uiState.dotCandidateText.observeForever(candidatesTextObserver)
        uiState.dashCandidateText.observeForever(candidatesTextObserver)
    }


}
```

Now we can add logic to `MorsoGestureListener`, which will notify the UiStateObserver when candidate values change.



```kotlin
    ...
    override fun onSingleTapUp(e: MotionEvent): Boolean {
        Log.d(TAG, "onSingleTapUp")
        morsoUiState.backgroundText.value.apply { "." }

        updateCandidates(MorseSignal.DOT)

        inputConnection.commitText("!", 1)

        return true
    }



    fun onHold(e: MotionEvent): Boolean {

        updateCandidates(MorseSignal.DASH)
        Log.d(TAG, "onHold")
        return true

    }

    private fun updateCandidates(signal: MorseSignal) {

        if (signal == MorseSignal.DOT){
            morsoUiState.currentCandidateText.value = morsoUiState.dotCandidateText.value

            val newCurrent = Character.fromString(morsoUiState.currentCandidateText.value.toString())

            morsoUiState.dotCandidateText.value = Character.getDotChild(newCurrent!!).toString()
            morsoUiState.dashCandidateText.value = Character.getDashChild(newCurrent!!).toString()
        }

        else if (signal == MorseSignal.DASH){
            morsoUiState.currentCandidateText.value = morsoUiState.dashCandidateText.value

            val newCurrent = Character.fromString(morsoUiState.currentCandidateText.value.toString())

            morsoUiState.dotCandidateText.value = Character.getDotChild(newCurrent!!).toString()
            morsoUiState.dashCandidateText.value = Character.getDashChild(newCurrent!!).toString()
        }
    }
```

Finally, we have to update our IME class:

```kotlin
class MorsoIME : InputMethodService() {
    private val TAG = "MorsoIME"
    lateinit var morsoInputView: MorsoInputView

+    lateinit var candidatesLayout: View
+    private var candidatesVisible = false

    lateinit var morsoGestureListener : MorsoGestureListener
    private val morsoUiState = MorsoUiState
    lateinit var morsoUiStateObserver: MorsoUiStateObserver



    /**
     * Create and return the view hierarchy used for the input area (such as
     * a soft keyboard).  This will be called once, when the input area is
     * first displayed.  You can return null to have no input area; the default
     * implementation returns null.
     *
     * <p>To control when the input view is displayed, implement
     * {@link #onEvaluateInputViewShown()}.
     * To change the input view after the first one is created by this
     * function, use {@link #setInputView(View)}.
     */
    override fun onCreateInputView(): View {
//        android.os.Debug.waitForDebugger()

        val morsoLayout = layoutInflater.inflate(R.layout.morso, null)
        morsoInputView = morsoLayout.findViewById<MorsoInputView>(R.id.morsoInputView)
        morsoGestureListener = morsoInputView.gestureListener
        morsoGestureListener.inputConnection = currentInputConnection
        morsoUiStateObserver = MorsoUiStateObserver(this, morsoUiState)

        setCandidatesViewShown(true)

        return morsoLayout
    }


    /**
     * Called when the input view is being shown and input has started on
     * a new editor.  This will always be called after {@link #onStartInput},
     * allowing you to do your general setup there and just view-specific
     * setup here.  You are guaranteed that {@link #onCreateInputView()} will
     * have been called some time before this function is called.
     *
     * @param info Description of the type of text being edited.
     * @param restarting Set to true if we are restarting input on the
     * same text field as before.
     */
    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
    }

+    override fun onCreateCandidatesView(): View {
+
+        candidatesVisible = true
+
+        candidatesLayout = layoutInflater.inflate(R.layout.candidates, null)
+
+        return candidatesLayout
+    }
+
+    override fun onFinishCandidatesView(finishingInput: Boolean) {
+        candidatesVisible = false
+        super.onFinishCandidatesView(finishingInput)
+    }

    /**
     * Called automatically from MorsoUiStateObserver whenever the state changes.
     */
+    fun updateUi() {
+        morsoInputView.updateUi(morsoUiState)
+
+        if (candidatesVisible) {
+            var current = candidatesLayout.findViewById<MorsoCandidateView>(R.id.morsoCurrentCandidate)
+            var dot = candidatesLayout.findViewById<MorsoCandidateView>(R.id.morsoDotCandidate)
+            var dash = candidatesLayout.findViewById<MorsoCandidateView>(R.id.morsoDashCandidate)
+
+            Log.d(TAG, "updateUi pre: ${current.text} ${dot.text} ${dash.text}")
+            current.text = morsoUiState.currentCandidateText.value
+            dot.text = morsoUiState.dotCandidateText.value
+            dash.text = morsoUiState.dashCandidateText.value
+            Log.d(TAG, "updateUi post: ${current.text} ${dot.text} ${dash.text}")
+
+
+            candidatesLayout.invalidate()
+        }
+
+    }

}
```

The result:

![Morso basic candidates operation GIF](/assets/images/blog-images/morso/candidates.gif)

<span class="todo">I just found out that there's a widget called [TextSwitcher](https://developer.android.com/reference/android/widget/TextSwitcher) which is useful for animating text labels.</span>

#### Sending Input

[Main article](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method#SendText)

Now that we register all the correct gestures and update the UI appropriately (and minimally, at this point), we can use Morso to send info to text fields.

First, we need to remove the background text reset logic from `MorsoUiStateObserver`:

```kotlin
 private fun observeBackgroundText() {
        // Create the observer which updates the UI.
        val backgroundTextObserver = Observer<String> {

            morso.updateUi()

-            if (uiState.backgroundText.value != "Morso") {
-                Handler(Looper.getMainLooper()).postDelayed({
-                    uiState.backgroundText.value = "Morso"
-                }, 1000)
-            }
        }

        // Observe the LiveData
        uiState.backgroundText.observeForever(backgroundTextObserver)
    }
```

Add a member `DEFAULT_BACKGROUND_TEXT` to `MorsoUiState`:

```kotlin
object MorsoUiState {

+    val DEFAULT_BACKGROUND_TEXT = "Morso"

    val backgroundText: MutableLiveData<String> by lazy {
!        MutableLiveData<String>(DEFAULT_BACKGROUND_TEXT)
    }

    // Default characters
    val currentCandidateText: MutableLiveData<String> by lazy {
            MutableLiveData<String>(Character.START.toString())
        }
    val dotCandidateText: MutableLiveData<String> by lazy {
        MutableLiveData<String>(Character.E.toString())
    }
    val dashCandidateText: MutableLiveData<String> by lazy {
        MutableLiveData<String>(Character.T.toString())
    }

    fun reset() {
!        backgroundText.value = DEFAULT_BACKGROUND_TEXT
        currentCandidateText.value = Character.START.toString()
        dotCandidateText.value = Character.E.toString()
        dashCandidateText.value = Character.T.toString()
    }
}
```

Now all we have to do is update our gesture listener actions:

```kotlin
...
    override fun onSingleTapUp(e: MotionEvent): Boolean {
        Log.d(TAG, "onSingleTapUp")

+        showUserInput(".")
        updateCandidates(MorseSignal.DOT)


        return true
    }



    fun onHold(e: MotionEvent): Boolean {
        Log.d(TAG, "onHold")

+        showUserInput("-")
        updateCandidates(MorseSignal.DASH)
        return true

    }

    fun onShortPause(e: MotionEvent): Boolean {
        Log.d(TAG, "onShortPause")
+        inputConnection.commitText(morsoUiState.currentCandidateText.value, 1)

+        morsoUiState.reset()
        return true
    }

    fun onLongPause(e: MotionEvent): Boolean {
        Log.d(TAG, "onLongPause")
+        inputConnection.commitText(" ", 1)

        return true
    }

+    private fun showUserInput(input: String) {
+
+        if (morsoUiState.backgroundText.value.equals(morsoUiState.DEFAULT_BACKGROUND_TEXT))
+            morsoUiState.backgroundText.value = input
+        else
+            morsoUiState.backgroundText.value += input
+
+    }

...
```

### Extras
We now have a basic input method! This is really all I wanted to accomplish - anything beyond this point is extra credit.

#### Adding Vibration

The [offical docs](https://developer.android.com/reference/android/os/Vibrator.html) on the Android Vibrator class is a bit sparse, so I got my info from [here](https://stackoverflow.com/a/13950364).

We need to specify that our app uses vibration in the manifest:

```xml
<uses-permission android:name="android.permission.VIBRATE"/>
```
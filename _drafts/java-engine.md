---
title: Creating a 3D Engine in Java using LWJGL
subtitle: 
excerpt: What does it take to create an engine in Java?
reason: To learn what it takes to create a performant engine, learn about real-time rendering, and brush up on Java
disclaimer:
toc: true
use-math: true
use-raw-images: true 
layout: post
author: Evan
header-image:
header-image-alt:
header-image-title:
tags: graphics java
---

## What is LWJGL?
> [Lightweight Java Game Library](https://www.lwjgl.org/)([GitHub](https://github.com/LWJGL/lwjgl3)) is a Java library that enables cross-platform access to popular native APIs useful in the development of graphics (OpenGL/Vulkan), audio (OpenAL) and parallel computing (OpenCL) applications. This access is direct and high-performance, yet also wrapped in a type-safe and user-friendly layer, appropriate for the Java ecosystem.

## Setting up LWJGL
I'll be following LWJGL's Installation Guide, which can be found [here](https://github.com/LWJGL/lwjgl3-wiki/wiki/1.2.-Install).

### Downloading LWJGL
I'll be using LWJGL's [configurator](https://www.lwjgl.org/customize) to download LWJGL with all default options selected *except* "Mode":

<div class="highlight-yellow">
Make sure you select the correct "natives" option selected. I'm creating this project on an aarch64(AKA arm64) chromebook, and x64 was checked by default.
</div>

> If you plan on using an IDE or need the actual .jar files, choose ZIP Bundle. If you are going to use maven or gradle, choose the respective option to generate a build script.

> Maven/Gradle is recommended during development. The zip bundle is recommended when creating a production build or installer for your application.  

I'll be using Gradle because I found the documentation to be superior to Maven's.

### Setting up Gradle
The Gradle installation instructions can be found [here](https://docs.gradle.org/current/userguide/installation.html#installation).

- install [SDKMAN!](https://sdkman.io/install) (Gradle is deployed and maintained *officially* on SDKMAN!)
- `sdk install gradle`
- `gradle init`

This is what we end up with:
<pre><code class="language-treeview">
JavaEngine/
├── app/
│   ├── bin/
│   │   ├── main/
│   │   │   └── javaengine/
│   │   │       └── App.class
│   │   └── test/
│   │       └── javaengine/
│   │           └── AppTest.class
│   ├── build/
│   │   ├── classes/
│   │   │   └── java/
│   │   │       ├── main/
│   │   │       │   └── javaengine/
│   │   │       │       └── App.class
│   │   │       └── test/
│   │   ├── generated/
│   │   │   └── sources/
│   │   │       ├── annotationProcessor/
│   │   │       │   └── java/
│   │   │       │       ├── main/
│   │   │       │       └── test/
│   │   │       └── headers/
│   │   │           └── java/
│   │   │               ├── main/
│   │   │               └── test/
│   │   └── tmp/
│   │       ├── compileJava/
│   │       │   └── previous-compilation-data.bin
│   │       └── compileTestJava/
│   ├── build.gradle
│   └── src/
│       ├── main/
│       │   ├── java/
│       │   │   └── javaengine/
│       │   │       └── App.java
│       │   └── resources/
│       └── test/
│           ├── java/
│           │   └── javaengine/
│           │       └── AppTest.java
│           └── resources/
├── gradle/
│   └── wrapper/
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── gradlew*
├── gradlew.bat
├── README.md
└── settings.gradle
</code></pre> 

You can read more about the Gradle scaffolding generated by `gradle init` [here](https://docs.gradle.org/current/samples/sample_building_java_applications.html#run_the_application). Check [here](https://docs.gradle.org/current/userguide/dependency_management.html) to learn more about Dependency management in Gradle.

Among other things, Gradle generates `JavaEngine/app/build.gradle`, which we'll add to using the partial `build.gradle` file generated from LWJGL's [configurator](https://www.lwjgl.org/customize):

<pre><code class="language-gradle">
/*
 * This file was generated by the Gradle 'init' task.
 *
 * This generated file contains a sample Java application project to get you started.
 * For more details take a look at the 'Building Java & JVM projects' chapter in the Gradle
 * User Manual available at https://docs.gradle.org/7.5.1/userguide/building_java_projects.html
 */

plugins {
    // Apply the application plugin to add support for building a CLI application in Java.
    id 'application'
}


project.ext.lwjglVersion = "3.3.1"
project.ext.lwjglNatives = "natives-linux-arm64"


repositories {
    // Use Maven Central for resolving dependencies.
    mavenCentral()
}

dependencies {
    // Use JUnit test framework.
    testImplementation 'junit:junit:4.13.2'

    // This dependency is used by the application.
    implementation 'com.google.guava:guava:31.0.1-jre'

    // LWJGL dependencies
    implementation platform("org.lwjgl:lwjgl-bom:$lwjglVersion")

	implementation "org.lwjgl:lwjgl"
	implementation "org.lwjgl:lwjgl-assimp"
	implementation "org.lwjgl:lwjgl-bgfx"
	implementation "org.lwjgl:lwjgl-cuda"
	implementation "org.lwjgl:lwjgl-egl"
	implementation "org.lwjgl:lwjgl-glfw"
	implementation "org.lwjgl:lwjgl-jawt"
	implementation "org.lwjgl:lwjgl-jemalloc"
	implementation "org.lwjgl:lwjgl-libdivide"
	implementation "org.lwjgl:lwjgl-llvm"
	implementation "org.lwjgl:lwjgl-lmdb"
	implementation "org.lwjgl:lwjgl-lz4"
	implementation "org.lwjgl:lwjgl-meow"
	implementation "org.lwjgl:lwjgl-meshoptimizer"
	implementation "org.lwjgl:lwjgl-nanovg"
	implementation "org.lwjgl:lwjgl-nfd"
	implementation "org.lwjgl:lwjgl-nuklear"
	implementation "org.lwjgl:lwjgl-odbc"
	implementation "org.lwjgl:lwjgl-openal"
	implementation "org.lwjgl:lwjgl-opencl"
	implementation "org.lwjgl:lwjgl-opengl"
	implementation "org.lwjgl:lwjgl-opengles"
	implementation "org.lwjgl:lwjgl-openxr"
	implementation "org.lwjgl:lwjgl-opus"
	implementation "org.lwjgl:lwjgl-par"
	implementation "org.lwjgl:lwjgl-remotery"
	implementation "org.lwjgl:lwjgl-rpmalloc"
	implementation "org.lwjgl:lwjgl-shaderc"
	implementation "org.lwjgl:lwjgl-spvc"
	implementation "org.lwjgl:lwjgl-stb"
	implementation "org.lwjgl:lwjgl-tinyexr"
	implementation "org.lwjgl:lwjgl-tinyfd"
	implementation "org.lwjgl:lwjgl-vma"
	implementation "org.lwjgl:lwjgl-vulkan"
	implementation "org.lwjgl:lwjgl-xxhash"
	implementation "org.lwjgl:lwjgl-yoga"
	implementation "org.lwjgl:lwjgl-zstd"
	runtimeOnly "org.lwjgl:lwjgl::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-assimp::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-bgfx::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-glfw::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-jemalloc::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-libdivide::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-llvm::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-lmdb::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-lz4::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-meow::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-meshoptimizer::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-nanovg::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-nfd::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-nuklear::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-openal::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-opengl::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-opengles::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-openxr::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-opus::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-par::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-remotery::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-rpmalloc::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-shaderc::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-spvc::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-stb::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-tinyexr::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-tinyfd::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-vma::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-xxhash::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-yoga::$lwjglNatives"
	runtimeOnly "org.lwjgl:lwjgl-zstd::$lwjglNatives"
}

application {
    // Define the main class for the application.
    mainClass = 'javaengine.App'
}

</code></pre>

Thanks to the `application` plugin, we can run the application from the command line:
<pre><code class="language-console">
./gradlew run

> Task :app:run
Hello world!

BUILD SUCCESSFUL
2 actionable tasks: 2 executed
</code></pre>
Read more about running our application (or any other Gradle questions you might have) [here](https://docs.gradle.org/current/samples/sample_building_java_applications.html#run_the_application).




### Testing our LWJGL Environment
Just to make sure that LWJGL is configured correctly, we can attempt to execute some code that prints the current LWJGL version. Let's replace the "Hello, World" code generated by Gradle in `app/src/main/java/javaengine/App.java` with the following:

<pre><code class="language-java">

package javaengine;

import org.lwjgl.Version;

public class App { 

    public static void main(String[] args) {
        System.out.println("LWJGL Version " + Version.getVersion() + " is working.");

    }
}
</code></pre>

<pre><code class="language-console">
./gradlew run

LWJGL Version 3.3.1 build 7 is working.
</code></pre>

## Hello, Window!
Now that we know everything is correctly set up, we can create a window! 

Create a new class `HelloWorld.java` at `JavaEngine/app/src/main/java/javaengine` and paste the following:

<pre><code class="language-java">
package javaengine;

import org.lwjgl.*;
import org.lwjgl.glfw.*;
import org.lwjgl.opengl.*;
import org.lwjgl.system.*;

import java.nio.*;

import static org.lwjgl.glfw.Callbacks.*;
import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.GL11.*;
import static org.lwjgl.system.MemoryStack.*;
import static org.lwjgl.system.MemoryUtil.*;

public class HelloWorld {

	// The window handle
	private long window;

	public void run() {
		System.out.println("Hello LWJGL " + Version.getVersion() + "!");

		init();
		loop();

		// Free the window callbacks and destroy the window
		glfwFreeCallbacks(window);
		glfwDestroyWindow(window);

		// Terminate GLFW and free the error callback
		glfwTerminate();
		glfwSetErrorCallback(null).free();
	}

	private void init() {
		// Setup an error callback. The default implementation
		// will print the error message in System.err.
		GLFWErrorCallback.createPrint(System.err).set();

		// Initialize GLFW. Most GLFW functions will not work before doing this.
		if ( !glfwInit() )
			throw new IllegalStateException("Unable to initialize GLFW");

		// Configure GLFW
		glfwDefaultWindowHints(); // optional, the current window hints are already the default
		glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE); // the window will stay hidden after creation
		glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE); // the window will be resizable

		// Create the window
		window = glfwCreateWindow(300, 300, "Hello World!", NULL, NULL);
		if ( window == NULL )
			throw new RuntimeException("Failed to create the GLFW window");

		// Setup a key callback. It will be called every time a key is pressed, repeated or released.
		glfwSetKeyCallback(window, (window, key, scancode, action, mods) -> {
			if ( key == GLFW_KEY_ESCAPE && action == GLFW_RELEASE )
				glfwSetWindowShouldClose(window, true); // We will detect this in the rendering loop
		});

		// Get the thread stack and push a new frame
		try ( MemoryStack stack = stackPush() ) {
			IntBuffer pWidth = stack.mallocInt(1); // int*
			IntBuffer pHeight = stack.mallocInt(1); // int*

			// Get the window size passed to glfwCreateWindow
			glfwGetWindowSize(window, pWidth, pHeight);

			// Get the resolution of the primary monitor
			GLFWVidMode vidmode = glfwGetVideoMode(glfwGetPrimaryMonitor());

			// Center the window
			glfwSetWindowPos(
				window,
				(vidmode.width() - pWidth.get(0)) / 2,
				(vidmode.height() - pHeight.get(0)) / 2
			);
		} // the stack frame is popped automatically

		// Make the OpenGL context current
		glfwMakeContextCurrent(window);
		// Enable v-sync
		glfwSwapInterval(1);

		// Make the window visible
		glfwShowWindow(window);
	}

	private void loop() {
		// This line is critical for LWJGL's interoperation with GLFW's
		// OpenGL context, or any context that is managed externally.
		// LWJGL detects the context that is current in the current thread,
		// creates the GLCapabilities instance and makes the OpenGL
		// bindings available for use.
		GL.createCapabilities();

		// Set the clear color
		glClearColor(1.0f, 0.0f, 0.0f, 0.0f);

		// Run the rendering loop until the user has attempted to close
		// the window or has pressed the ESCAPE key.
		while ( !glfwWindowShouldClose(window) ) {
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // clear the framebuffer

			glfwSwapBuffers(window); // swap the color buffers

			// Poll for window events. The key callback above will only be
			// invoked during this call.
			glfwPollEvents();
		}
	}
}

</code></pre>

Call `HelloWorld.run()` from our main method in `App.java`:
<pre><code class="language-java">
package javaengine;

public class App {

	public static void main(String[] args) {
		new HelloWorld().run();
	}

}
</code></pre>

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

## Getting Started with LWJGL
LWJGL's Getting Started guide can be found [here](https://github.com/LWJGL/lwjgl3#getting-started) and the Installation Guide [here](https://github.com/LWJGL/lwjgl3-wiki/wiki/1.2.-Install).

### Downling LWJGL
I'll be using LWJGL's [configurator](https://www.lwjgl.org/customize) to download LWJGL with all default options selected*except* "Mode":

> If you plan on using an IDE or need the actual .jar files, choose ZIP Bundle. If you are going to use maven or gradle, choose the respective option to generate a build script.

> Maven/Gradle is recommended during development. The zip bundle is recommended when creating a production build or installer for your application.  

I honestly chose Maven over Gradle because it looks better: ![Maven vs Gradle](/assets/images/blog-images/java-engine/gradle-vs-maven.gif)

### Installing Maven
Installation instructions for Maven can be found [here](https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html).

In your project directory run the following command:

```console
mvn archetype:generate -DgroupId=com.eldun.java-engine -DartifactId=java-engine -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false
```
After moving some files around, this is what my project folder looks like:


```treeview
.
├── pom.xml
├── README.md
└── src/
    ├── main/
    │   └── java/
    │       └── com/
    │           └── eldun/
    │               └── java-engine/
    │                   └── App.java
    └── test/
        └── java/
            └── com/
                └── eldun/
                    └── java-engine/
                        └── AppTest.java
```

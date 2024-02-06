---
title: "Getting Familiar with Java Spring Boot"
subtitle:
excerpt: "In a recent interview, I was informed that it might be beneficial for me to learn a smidge about Spring Boot before the second interview. This is me, familiarizing."
use-math: true
use-raw-images: false
toc: true
layout: post
author: Evan
header-image: /assets/images/blog-images/spring-boot/spring-boot-logo.png
header-image-alt: "A pleasant green hexagon with a power symbol punched out of the center."
header-image-title: "Spring Boot logo"
tags: java web spring
---

### What is Spring?
[Spring](https://spring.io/) is a Java [framework](https://www.codecademy.com/resources/blog/what-is-a-framework/) - the world's [most popular](https://snyk.io/blog/jvm-ecosystem-report-2018-platform-application/).

---

### What is Spring Boot?
From Spring's [documentation](https://spring.io/projects/spring-boot):

> Spring Boot makes it easy to create stand-alone, production-grade Spring based Applications that you can "just run".
>
> We take an opinionated view of the Spring platform and third-party libraries so you can get started with minimum fuss. Most Spring Boot applications need minimal Spring configuration.

With such features as:

- Create stand-alone Spring applications
- Embed Tomcat, Jetty or Undertow directly (no need to deploy WAR files)
- Provide opinionated 'starter' dependencies to simplify your build configuration
- Automatically configure Spring and 3rd party libraries whenever possible
- Provide production-ready features such as metrics, health checks, and externalized configuration
- Absolutely no code generation and no requirement for XML configuration

If you want to read more about the differences betweeen Spring and Spring Boot, you can check out [this article](https://www.baeldung.com/spring-vs-spring-boot).

---

### Getting Started with Spring's Guides
Spring has a few suggested guides on their [Spring Boot page](https://spring.io/projects/spring-boot). Let's start from the start with the [Quickstart guide](https://spring.io/quickstart).

---

#### The [Quickstart Guide](https://spring.io/quickstart)
The goal here, of course, is to build a classic "Hello, World" endpoint.


##### Project configuration
We'll start by creating a new Spring Boot "web" projecet using a .zip generated from [start.spring.io](https://start.spring.io/).

![start.spring.io](/assets/images/blog-images/spring-boot/quickstart-1.png)

##### Adding our Code
Here's the diff between the generated code and what we're adding:

```java
package com.example.quickstart1;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
+ import org.springframework.web.bind.annotation.GetMapping;
+ import org.springframework.web.bind.annotation.RequestParam;
+ import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
+ @RestController
public class Quickstart1Application {

    public static void main(String[] args) {
      SpringApplication.run(Quickstart1Application.class, args);
    }

+   @GetMapping("/hello")
+   public String hello(@RequestParam(value = "name", defaultValue = "World") String name) {
+     return String.format("Hello %s!", name);
+   }
}

```

That's it! Obviously, `hello()` can accept a name. The `@RestController` annotation lets Spring know that this code descibes an endpoint. `@GetMapping("/hello")` tells spring to use `hello()` to answer requests sent to `localhost:8080/hello`. `@RequestParam` tells Spring to expect a name value, defaulting to `"World"`.`

##### Running Hello World

To run our application (with Maven):

```cmd

evan@pop-os:~/Projects/eldun/SpringBoot/quickstart1$ ./mvnw spring-boot:run


```

Visit `http://localhost:8080/hello` and you'll see something like this:

![Our working "Hello World" endpoint](/assets/images/blog-images/spring-boot/quickstart-1-result.png)

Add `?name=YourName` to the end of the URL to pass a parameter.


#### Building a Simple Web App with Spring Boot

Based on the guide found [here](https://spring.io/guides/gs/spring-boot/).

##### Getting Started

Let's create another initialized Spring Boot project using [start.spring.io](https://start.spring.io/). We'll call this one `simple-web-app`.

##### Creating the Web Controller
We'll create the following controller:

```java 

package main.java.com.example.Application;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

	@GetMapping("/")
	public String index() {
		return "Greetings from Spring Boot!";
	}

}

```

> The class is flagged as a @RestController, meaning it is ready for use by Spring MVC to handle web requests. @GetMapping maps / to the index() method. When invoked from a browser or by using curl on the command line, the method returns pure text. That is because @RestController combines @Controller and @ResponseBody, two annotations that results in web requests returning data rather than a view.


##### Creating our Application Class

The Spring Inititalizr creates the following class for us:

```java
package com.example.Application;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

}


```

We need to beef it up a bit:

```java 
package com.example.Application;

import java.util.Arrays;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

	@Bean
	public CommandLineRunner commandLineRunner(ApplicationContext ctx) {
		return args -> {

			System.out.println("Let's inspect the beans provided by Spring Boot:");

			String[] beanNames = ctx.getBeanDefinitionNames();
			Arrays.sort(beanNames);
			for (String beanName : beanNames) {
				System.out.println(beanName);
			}

		};
	}

}

```


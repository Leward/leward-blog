---
layout:     post
title:      "Simple JavaFX project won't run with IntelliJ"
slug:       simple-javafx-project-wont-run-in-intellij
date:       2020-10-21 23:32:00 -0400
categories:
lang:       en
ref:        simple-javafx-project-wont-run-in-intellij
excerpt_separator: <!--more-->
---

If you try to run a simple JavaFX project like the one I used for my ["Native GUI app with JavaFX"]({% post_url 2020-10-18-EN-native-gui-app-with-javafx %}) article in IntelliJ, you will run an error that looks like this:

```
Exception in Application start method

(...)

Caused by: 
    java.lang.IllegalAccessError: superclass access check failed: class com.sun.javafx.scene.control.ControlHelper (in unnamed module @0x183c1801) cannot access class com.sun.javafx.scene.layout.RegionHelper (in module javafx.graphics) because module javafx.graphics does not export com.sun.javafx.scene.layout to unnamed module @0x183c1801
```

<!--more-->

Yet if you run the project using the `mvn javafx:run` command it will work just fine:

![The application will launch from the maven command](/assets/2020-10-21-simple-javafx-project-wont-run-in-intellij/mvn-javafx-run.png)

It looks like IntelliJ is not configuring the modules/classpath correctly out of the box.

A way to remediate this is to provide a module descriptor (`module-info.java`):

```java
// hellofx/src/main/java/module-info.java

module eu.leward.hellofx {
    requires javafx.controls;

    opens eu.leward.hellofx to javafx.graphics;
}
```

You won't need to add a `require` for `[javafx.graphics](http://javafx.graphics)` and `javafx.base` since those are transitive requirements from `javafx.controls.`

Now, you can click on the "Run" button for `HelloFX` in Intellij and the application will start as expected.

Quick reminder on modules: 

- **`module eu.leward.hellofx`** indicates the **name** of the module, I decided to follow a naming convention, but it can be any name you want `module toto` will work too even though it may not be the best name
- **`opens eu.leward.hellofx to javafx.graphics;`** here `eu.leward.hellofx` is a Java package name, not the name of module!
- **`opens to`** is used because `main` uses the `launch()` method which does some refection to instantiate and run the application. 
 <br>Using Java modules, you need to allow that reflection access using `opens`. You won't get this error if you use [classpath instead of modulepath](https://gorillalogic.com/blog/understanding-java-9-modules/), however I believe modules and modulepath is the way forward.


## Maven Compiler Plugin

If you don't make any modification to you `pom.xml`, running `mvn compile` will now result in an error:

```
 Compilation failure
[ERROR] /helofx/src/main/java/module-info.java:[2,20] module not found: javafx.controls
```

If you specify anything, maven will use by default an old version of the `maven-compiler-plugin`. So you need to specify a more recent version (>= 3.7.0) for compilation with modules to work:

```xml
<plugins>
  <plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <version>3.8.1</version>
  </plugin>
</plugins>
```

With that out of the way, happy building and compiling!

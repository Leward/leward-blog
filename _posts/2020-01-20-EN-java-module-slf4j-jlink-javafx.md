---
layout:     post
title:      "Java Modules with JavaFX, Slf4j, Logback and jlink"
slug:       java-module-slf4j-jlink-javafx
date:       2020-01-20 05:35:00 +0800
categories:
lang:       en
ref:        java-module-slf4j-jlink-javafx
excerpt_separator: <!--more-->
---

I recently tried to upgrade an old JavaFX application I had as a side-project to a more recent version of Java: Java 13 at the time of writing this.

Most of my work with Java so far was on Java 8. I hardly did the switch to Java 9+ besides keeping informed by reading some articles on the matter ([Baeldung](https://www.baeldung.com/) and [Java Annotated](https://blog.jetbrains.com/idea/tag/java-annotated/)). 

One of the issues I had during the migration was to use [Java modules](https://blog.codefx.org/java/java-module-system-tutorial/) and produce a runtime image with [jlink](https://docs.oracle.com/en/java/javase/11/tools/jlink.html).

<!--more-->

# module-info.java

I wanted to have the following `module-info.java`:

    module graph.designer {
        requires javafx.controls;
        requires javafx.fxml;
        requires org.slf4j;
        requires ch.qos.logback.classic;
    
        opens fr.leward.graphdesigner to javafx.fxml;
        exports fr.leward.graphdesigner;
    }

# Build with jlink

`mvn javafx:run` would run just fine. However `mvn javafx:jlink` returned the following error: 

    Error: automatic module cannot be used with jlink: org.slf4j from file:///home/leward/.m2/repository/org/slf4j/slf4j-api/1.7.30/slf4j-api-1.7.30.jar

What happens here is slf4j-api in its version 1.7.30 is not a native java module. It worked with the simple run command because Java automatically converts jars into java modules. However jlink is more particular about it and only want proper Java modules.

**Note**: do not confuse Java modules and Maven modules. They have the same name but are different things. 

# The fix

The fix was to simply go for a more recent version, which at the time of writing are not yet stable. 

    <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>slf4j-api</artifactId>
        <version>2.0.0-alpha1</version> <!-- 01-Oct-2019 -->
    </dependency>
    
    <dependency>
        <groupId>ch.qos.logback</groupId>
        <artifactId>logback-classic</artifactId>
        <version>1.3.0-alpha5</version> <!-- 22-Oct-2019 -->
    </dependency>

Even though though are Alpha versions, slf4j and logback projects are not known for easily breaking compatibilities. So if you want to use them for small projects you don't risk much. For critical enterprise software it's a different story... 

Note: You'd usually put the logback pendency as a runtime dependency, but here we need it to build the image and run it. Runtime dependency is a Maven construct, which is different from the Java Module System. An alternative is to have an image without logback and add the logback module when launchin the app. However I went for convinience and simplicity here.

Now I can build with `mvn javafx:jlink` and run the generated image (`target/graph-designer/launcher`). You can read more about this on the [OpenJFX Getting Started Guide](https://openjfx.io/openjfx-docs/#modular).

There is a [tiny demo project I pushed to GitHub|https://github.com/Leward/demo-modules-fx] if you want to see and run the code.
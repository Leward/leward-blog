---
layout:     post
title:      "Native GUI app with JavaFX"
slug:       native-gui-app-with-javafx
date:       2020-10-18 21:30:00 -0400
categories:
lang:       en
ref:        native-gui-app-with-javafx
excerpt_separator: <!--more-->
---

For this guide, I am building the application on Linux. Note that because we will end up compiling a native app, the binary will only work on a Linux system with the same architecture.

By doing so, we lose the "build once, run everywhere" of Java. In exchange we get faster start time and lesser memory footprint for our programs. Also, the end users will not be required to have the Java Runtime Environment (JRE) installed on their systems.

<!--more-->

If you are running Windows, you can check out [my follow-up post on how to compile a native JavaFX application on Windows](/2020/02/21/native-gui-app-with-javafx-windows.html).

## Setup

```bash
# Install SDKMAN!
$ curl -s "https://get.sdkman.io" | bash

# Install GraalVM
# TODO: a note on graal versioning
$ sdk install 20.2.0.r11-grl

# Let`s check which version of java we are using
# Note: With SDKMAN!, you can install and switch between multiple java versions
$ java -version
openjdk version "11.0.8" 2020-07-14
OpenJDK Runtime Environment GraalVM CE 20.2.0 (build 11.0.8+10-jvmci-20.2-b03)
OpenJDK 64-Bit Server VM GraalVM CE 20.2.0 (build 11.0.8+10-jvmci-20.2-b03, mixed mode, sharing)

# We will also need the Maven build tool.
# Note: you can use Gradle too, this tutorial focuses on Maven.
sdk install maven

# Native image will be used to compile to a native binary.
gu install native-image
```

## Minimal Java FX project

Let's start by writing a minimal "Hello World!" java program.

```bash
# Create a basic directory structure
mkdir -p hellofx/src/main/java/eu/leward/hellofx
```

Create the `pom.xml` file, describing our Maven project and build.

```xml
<!-- hellofx/pom.xml -->

<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>eu.leward</groupId>
  <artifactId>hellofx</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>hellofx</name>
  <url>http://maven.apache.org</url>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>1.6</maven.compiler.source>
    <maven.compiler.target>1.6</maven.compiler.target>
</properties>

  <dependencies>
    <dependency>
      <groupId>org.openjfx</groupId>
      <artifactId>javafx-controls</artifactId>
      <version>15</version>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.openjfx</groupId>
        <artifactId>javafx-maven-plugin</artifactId>
        <version>0.0.5</version>
        <configuration>
          <mainClass>eu.leward.hellofx.HelloFX</mainClass>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

We only need a single Java file for our example.

```java
// hellofx/src/main/java/eu/leward/hellofx/HelloFX.java

package eu.leward.hellofx;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;

public class HelloFX extends Application {

    @Override
    public void start(Stage stage) {
        String javaVersion = System.getProperty("java.version");
        String javafxVersion = System.getProperty("javafx.version");
        Label l = new Label("Hello, JavaFX " + javafxVersion + ", running on Java " + javaVersion + ".");
        Scene scene = new Scene(new StackPane(l), 640, 480);
        stage.setScene(scene);
        stage.show();
    }

    public static void main(String[] args) {
        launch();
    }

}
```

Some explanation of what's going on here.

We can run the project as a regular Java application: 

```bash
mvn clean javafx:run
```

![HelloFX running as a regular Java program](/assets/2020-10-18-native-gui-app-with-javafx/run-regular-java.png)

That's the extent of the Java programming we will be doing for this tutorial.

## Compiling as a native app

Until this part, you actually didn't need to have GraalVM installed, any recent JDK would be good. However, you need GraalVM for compiling the project as a native binary. 

In order to achieve this, the folks at [Gluon](https://gluonhq.com/) have developed a convenient Maven plugin: 

> If you have a Java or JavaFX project and you are using Maven as a build tool, you can easily include the plugin to start creating native applications.

In order to add the plugin, add the following to your `pom.xml` file:

```xml
<plugin>
  <groupId>com.gluonhq</groupId>
  <artifactId>client-maven-plugin</artifactId>
  <version>0.1.31</version>
  <configuration>
    <mainClass>eu.leward.hellofx.HelloFX</mainClass>
  </configuration>
</plugin>
```

You can build the native executable for program using `mvn client:build`

You will need to have a `GRAALVM_HOME` environment variable for the plugin to work. You actually don't need to run that GraalVM installation as you main java version, since the plugin will use that `GRAALVM_HOME` directory to locate the `native-image` tool it requires.

If it fails, read carefully the error messages, it may ask you to install some libraries to be able to compile the program.

For the example I am passing the environment variable before running the command: 

```bash
GRAALVM_HOME=~/.sdkman/candidates/java/20.2.0.r11-grl mvn client:build
```

Ahead Of Time (AOT) compilation will be taxing on your system. 

![100% CPU utilization](/assets/2020-10-18-native-gui-app-with-javafx/cpu-usage.png)

I'm running on an old XPS 13, which is definitely lacking CPU horsepower.

- `mvn client:build` takes ~ 4 minutes
- `mvn package` take a few seconds

Let's look at the resulting binary.

```xml
$ du -h target/client/x86_64-linux/hellofx 
62M	target/client/x86_64-linux/hellofx
```

62 Megabytes, that not a small size for an hello world. Keep in mind, this is still Java and bits of the JDK needs to be included in your binary. I did not explore if there are ways to trim this down using the Java module system. 

Run it with: `target/client/x86_64-linux/hellofx`

![HelloFX running as a native binary](/assets/2020-10-18-native-gui-app-with-javafx/run-compiled.png)

## Final Notes

This is a simple project, there is no reflection involved. If you use some annotation, it's very likely reflection is involved at some point. When that's the case you need to guide the compiler. I may write a following post on that topic.

When the word "native" is used you should understandit as "native binary" that be executing by the target operating system and architecture without a Java Runtime Environment. This is still a JavaFX, using a JavaFX GUI toolkit, not the native GUI toolkit of the system.

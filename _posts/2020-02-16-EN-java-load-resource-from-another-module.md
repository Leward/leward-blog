---
layout:     post
title:      "Load a Resource from another Module in Java (With Maven)"
slug:       java-load-resource-from-another-module
date:       2020-02-16 23:53:00 +0800
categories:
lang:       en
ref:        java-load-resource-from-another-module
excerpt_separator: <!--more-->
---

Trying to put some resources on their own module on a Java 13 project, I ran into some issues where I could not load the resource. The idea was to reuse these resources (configs, styles, etc.) on multiple modules of my project. 

<!--more-->

Given a simple Maven project: 

- parent
    - app
    - config

Where module `app` depends on (requires) module `configs`.

Even though I am using Java 13 in this example, this should apply to a Java 11+ project.

# Using Java 13, no module configured

When you have a Maven project without any `module-info.java` file, the good old classpath mechanism (as opposed to java modules) is used.

File structure:

```
.
├── app
│   ├── pom.xml
│   ├── src
│   │   ├── main
│   │   │   ├── java
│   │   │   │   └── org
│   │   │   │       └── example
│   │   │   │           └── app
│   │   │   │               └── Main.java
├── configs
│   ├── pom.xml
│   ├── src
│   │   ├── main
│   │   │   ├── java
│   │   │   └── resources
│   │   │       └── configs
│   │   │           └── app.ini
└── pom.xml
```

```java
// Main.java
package org.example.app;

import java.io.IOException;
import java.net.URL;

public class Main {
  public static void main(String[] args) throws IOException {
    System.out.printf("Hello, let me read the config!%n");

    URL url = Main.class.getResource("/configs/app.ini");
    String content = new String(url.openStream().readAllBytes());
    System.out.println(content);
  }
}
```

This results in:

```
Hello, let me read the config!
value=test
```

This actually looks good. What happen if we throw some Java Module System into the mix? 

# Using Java 13, with modules

Our Java modules will reflect our Maven modules: 

```java
// app/src/main/java/module-info.java
module org.example.app {
  requires org.example.configs;
}

// configs/src/main/java/module-info.java
module org.example.configs {
}
```

**On module names:** I don't have name my modules `org.example.app`, you could just name it `app`. I believe it's a good practice to have some kind of qualifier to differenciate your module over modules outside your project. It's kind of the same reasoning that we used to use to name java packages.

Now, running `Main` gives the following error: 

    Hello, let me read the config!
    Exception in thread "main" java.lang.NullPointerException
    	at app/org.example.app.Main.main(Main.java:12)

Oh no! Not quite what we expected. What happened here?

- The resource has to be in a exported package.
- Moreover, to load the resource with `module.getResourceAsStream()`, the package should be opened, not simply exported.
- It's OK if there is no class in `src/main/java`

Note how the `configs/src/main/resources` folder has changed.

```
.
├── app
│   ├── pom.xml
│   └── src
│       ├── main
│       │   ├── java
│       │   │   ├── module-info.java
│       │   │   └── org
│       │   │       └── example
│       │   │           └── app
│       │   │               └── Main.java
│       │   └── resources
│       └── test
│           └── java
├── configs
│   ├── pom.xml
│   └── src
│       ├── main
│       │   ├── java
│       │   │   └── module-info.java
│       │   └── resources
│       │       └── org.example.configs
│       │           └── app.ini
│       └── test
│           └── java
└── pom.xml
```

Some modifications have to be made to our module defnitions and `Main.java`:

```java
// app/src/main/java/module-info.java
module org.example.app {
  requires org.example.configs;
}

// configs/src/main/java/module-info.java
module org.example.configs {
  opens org.example.configs;
}
```

```java
// Main.java
package org.example.app;

import java.io.IOException;
import java.io.InputStream;

public class Main {
  public static void main(String[] args) throws IOException {
    System.out.printf("Hello, let me read the config!%n");

    InputStream stream = ClassLoader
      .getSystemResources("org.example.configs/app.ini")
      // Note that multiple matches are technically possible!
      .nextElement()
      .openStream();

    System.out.println(new String(stream.readAllBytes()));
  }
}
```

Now it's all working as I wanted:

```
Hello, let me read the config!
value=test
```

In the end I, what I struggled with, was to figure out how to properly export my resource to another package. 

## Alternative way to read resource from a module

By using `ClassLoader.getSystemResources` it is possible to get multiple matches depending on what is on your module path.

You can aim for a resource in a particular module, using the following snippet.

```java
package org.example.app;

import java.io.IOException;
import java.io.InputStream;

public class Main {
  public static void main(String[] args) throws IOException {
    System.out.printf("Hello, let me read the config!%n");

    Module module = ModuleLayer.boot()
      .findModule("org.example.configs")
      // Optional<Module> at this point
      .orElseThrow();
    InputStream stream = module.getResourceAsStream("org.example.configs/app.ini");

    System.out.println(new String(stream.readAllBytes()));
  }
}
```


---
layout:     post
title:      "Write a user guide in a Maven project using Asciidoctor"
slug:       "write-user-guide-maven-project-with-asciidoctor"
date:       2017-08-05 14:24:00 +0800
categories:
lang:       en
ref:        write-user-guide-maven-project-with-asciidoctor
excerpt_separator: <!--more-->
---

On my current engagement for a client at [Zenika](http://www.zenika.sg) I work on an authentication module that is going to be used by many applications. 

The fact that many applications are going to rely on us makes documentation what we do quite important. So far we used Swagger in order to document our REST API thanks to [Springfox](http://springfox.github.io/springfox/) and some documentation that we tried to maintain in Confluence. 

<!--more-->

## Our documentation problem

The Swagger documentation overall can always be improved but it did quite a good job at documenting our API contracts and people used it quite a lot. What was lacking, however, was a proper user guide, gor users to properly understand what our authentication module is about and how to integrate with it. I had to explain the workflow to every consumer and that is far from ideal. 

We also lacked documentation explaining how to setup the project and all the possible configurations such as the external systems to connect to, the database configuration, the authentication flow (groovy DSL to configure authentication screens - I should write an article about this) and whether to use mocks or not. 

We actually to put some documentation in Confluence, but it is not easy to organize, is used by many people for different purpose. The documentation we put there was eventually behind the god and not versionned. Versionning of the documentation is useful if you have multiple deployments of the same software which could be of different versions. 

That's why in the team we decided to try to tight our documentation into our codebase. So that it will follow the code evolutions, can be compiled and published automatically. From now on we can also more easily integrate documentation tasks and review as part of our Pull Requests and code reviews. 

## Implementation of documentation in code using Asciidoctor

The project is a Spring project and we use Maven to build the project. It turns out that Spring themesevles write [some of their documentations](http://cloud.spring.io/spring-cloud-static/spring-cloud-config/1.3.1.RELEASE/) using [Asciidoctor](http://asciidoctor.org) and their is an [Asciidoctor Maven plugin](https://github.com/asciidoctor/asciidoctor-maven-plugin) available. 

To start with Asciidoctor on your existing Maven project add the asciidoctor plugin in your `pom.xml`: 

```xml
<plugin>
    <groupId>org.asciidoctor</groupId>
    <artifactId>asciidoctor-maven-plugin</artifactId>
    <version>1.5.5</version>
    <executions>
        <execution>
            <id>asciidoc-html</id>
            <phase>generate-resources</phase>
            <goals>
                <goal>process-asciidoc</goal>
            </goals>
            <configuration>
                <backend>html</backend>
            </configuration>
        </execution>
    </executions>
</plugin>
```

We add `asciidoctor-maven-plugin` to our build and configure it to attach the generation of the documentation to the Maven `generate-resources` phase. The only configuration we need to specify is that we want the documentation generated in HTML.

The maven build being configured, we can now right the documentation. By default the documation as to be located under the `src/main/asciidoc` directory.

Then create an `index.adoc` file with the following content:

```asciidoc
= MyIdeas User Guide

This is a user manual for an example project.

== Introduction

This project does something.
We just haven't decided what that is yet.
```

To generate the documentation in HTML format, run: `mvn clean package` and you should have a `target/generated-docs/index.html` file generated.

[![Our first generated documentation](/assets/2017-08-05-write-user-guide-in-maven-project-with-asciidoctor/first-doc-generated.png)](/assets/2017-08-05-write-user-guide-in-maven-project-with-asciidoctor/first-doc-generated.png)

We can already see that it comes with a neat default theme and the footer includes the generation date. 

## Tips and tricks

### Include project version number

To track which version of the software the generated document it is possible to include the version of the Maven project in the header of the generated document. The [plugin's documentation](https://github.com/asciidoctor/asciidoctor-maven-plugin#add-version-and-build-date-to-the-header) describes how to configure it: 

```xml
<properties>
   <!-- Custom date format to be displayed -->
   <maven.build.timestamp.format>dd MMMM yyyy HH</maven.build.timestamp.format>
</properties>

<configuration>
    ...
    <attributes>
        ...
        <revnumber>${project.version}</revnumber>
        <revdate>${maven.build.timestamp}</revdate>
        <organization>${project.organization.name}</organization>
    </attributes>
    ...
</configuration>
```

[![Maven version number in the header](/assets/2017-08-05-write-user-guide-in-maven-project-with-asciidoctor/doc-with-version-number.png)](/assets/2017-08-05-write-user-guide-in-maven-project-with-asciidoctor/doc-with-version-number.png)

### Include code snippets from actual code

You can also link actual code snippets from the project without having to copy them. This means your documentation never get out of sync if a code example change. 

First, define the `sourcedir` attribute in order to inscruct the plugin where to look for source code: 

```xml
<attributes>
    <sourcedir>${project.build.sourceDirectory}</sourcedir>
</attributes>
```

Then in your documentation you can use this reference to include code snippets: 

```asciidoc
== Code from the project

[source,java]
.Java code from project
----
include::{sourcedir}/eu/leward/asciidocdemo/IdeaController.java[tags=class]
----
```

Noticed the `[tags=class]`? The brackets after the file you want to include give more details about how the inclusion should be done. Here we don't want to show the whole file as we are not interested in the java imports. 

In order to extract a subset of the file you can put tags in the source code: 

```java
package eu.leward.asciidocdemo;
import org.springframework.web.bind.annotation.RestController;
// tag::class[]
@RestController
public class IdeaController { }
// end::class[]
```

By leaving the brackets empty you can display the whole file 

```asciidoc
include::{sourcedir}/eu/leward/asciidocdemo/IdeaController.java[]
```

[![Documentation with code snippet from the actual project source code](/assets/2017-08-05-write-user-guide-in-maven-project-with-asciidoctor/doc-with-code-snippet.png)](/assets/2017-08-05-write-user-guide-in-maven-project-with-asciidoctor/doc-with-code-snippet.png)

A good usecases would be to have in the documentation some snippets that are unit tests. They are often short example and the project will benefits from the automatic tests. 

## About the Asciidoc syntax

The Asciidoc syntax is, like Markdown, lightweight and aims at making the document written in Asciidoc easily readable without beiing processed or converted. 

When using Asciidoctor, a lot of the syntax elements [are the same as in markdown](http://asciidoctor.org/docs/asciidoc-syntax-quick-reference/#markdown-compatibility) such as headings, paragraphs, formatting, links, images, source code, etc. 

However there are some differences and more important Asciidoc comes more possibilities in its syntax than regular Markdown or even GitHub flavoured markdown. 

You can find a [reference of Asciidoc syntax on the official documentation](http://asciidoctor.org/docs/asciidoc-syntax-quick-reference/). 

## Links

* [Examples used in this article on Github](https://github.com/Leward/swagger-asciidoc-demo)
* [AsciiDoc Syntax Quick Reference](https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/)
* [Asciidoctor website](http://asciidoctor.org)
* [Asciidoctor Maven plugin](https://github.com/asciidoctor/asciidoctor-maven-plugin)
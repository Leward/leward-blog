---
layout:     post
title:      "JSON Editor with RichTextFX (part 2)"
slug:       json-editor-with-richtextfx-part-2
date:       2020-12-12 00:32:00 -0400
categories: 100-days-javafx
lang:       en
ref:        json-editor-with-richtextfx-part-2
excerpt_separator: <!--more-->
---

In [the part 1]({% post_url 2020-12-08-EN-json-editor-with-richtextfx-part-1 %}) we discovered how to use the capabilities of the [`CodeArea`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/CodeArea.html) component from [the RichTextFX library](https://github.com/FXMisc/RichTextFX) in order to have a textarea suited for editing code and which can render rich text.

In this part we base on this to build a JSON syntax highlighter for the JSON Editor of [our JSON Schema application]({% post_url 2020-11-14-EN-new-project-json-schema-app %}).

<!--more-->

## Leveraging Jackson Parser

Jackson is a good and popular option when it comes to work with JSON in the Java ecosystem. We are interesting in leveraging the [`JsonParser`](https://fasterxml.github.io/jackson-core/javadoc/2.12/com/fasterxml/jackson/core/JsonParser.html) class to break down our JSON String into JSON tokens and apply styling to those individual tokens.

Add Jackson dependency the your `pom.xml` file. Also don't forget to add `requires com.fasterxml.jackson.core;` to you `module-info.java` file.

```xml
<!-- pom.xml -->
<dependency>
  <groupId>com.fasterxml.jackson.core</groupId>
  <artifactId>jackson-core</artifactId>
  <version>2.12.0</version>
</dependency>
```

Below is a simple example of how the [`JsonParser`](https://fasterxml.github.io/jackson-core/javadoc/2.12/com/fasterxml/jackson/core/JsonParser.html) can be used to parse and extract tokens from a JSON string.

```java
String code = "{\"a\": 5}";
JsonFactory jsonFactory = new JsonFactory();
JsonParser parser = jsonFactory.createParser(code);
while (!parser.isClosed()) {
  JsonToken jsonToken = parser.nextToken();
  // TODO: Work with the json token
}
```

Because we are parsing JSON for the purpose of syntax highlighting we can ingore JSON Parsing exceptions and just not (or partially) highlight invalid JSON.

## CSS classes

As seen [in the previous post]({% post_url 2020-12-08-EN-json-editor-with-richtextfx-part-1 %}), we need to create CSS classes in order to apply styling to the [`CodeArea`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/CodeArea.html).

```css
/* src/main/resources/style.css */

.json-property { -fx-fill: blue; }
.json-number   { -fx-fill: purple; }
.json-string   { -fx-fill: red; }
```

The following method will also help us turn a [`JsonToken`](https://fasterxml.github.io/jackson-core/javadoc/2.7/com/fasterxml/jackson/core/JsonToken.html) to a CSS class:

```java
public static String jsonTokenToClassName(JsonToken jsonToken) {
  if (jsonToken == null) {
    return "";
  }
  switch (jsonToken) {
    case FIELD_NAME:
      return "json-property";
    case VALUE_STRING:
      return "json-string";
    case VALUE_NUMBER_FLOAT:
    case VALUE_NUMBER_INT:
      return "json-number";
    default:
      return "";
  }
}
```

## JSON Highilighting Class

In order to keep the logic in `EditingPane` as simple as possible, the highlighting logic will take place in seaparated class.

```java
package eu.leward.jschema.highlighting;

class Json {
  private final JsonFactory jsonFactory = new JsonFactory();

  public StyleSpans<Collection<String>> highlight(String code) {
    StyleSpansBuilder<Collection<String>> spansBuilder = new StyleSpansBuilder<>();
    // TODO: Apply styling
    return spansBuilder.create();
  }
}
```

This won't do much, but gives some foundation to build on.

### JSON Syntax Highlighting using Jackson

For each [`JsonToken`](https://fasterxml.github.io/jackson-core/javadoc/2.7/com/fasterxml/jackson/core/JsonToken.html) matched, we will assign a CSS class if we want to color it and then add a new [`StyleSpan`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/model/StyleSpan.html) for that token.

```java
public StyleSpans<Collection<String>> highlight(String code) {
  StyleSpansBuilder<Collection<String>> spansBuilder = new StyleSpansBuilder<>();

  try {
    JsonParser parser = jsonFactory.createParser(code);
    while (!parser.isClosed()) {
      JsonToken jsonToken = parser.nextToken();
      
      int length = parser.getTextLength();
      // Because getTextLength() does contain the surrounding ""
      if(jsonToken == JsonToken.VALUE_STRING || jsonToken == JsonToken.FIELD_NAME) {
        length += 2;
      }

      String className = jsonTokenToClassName(jsonToken);
      if (!className.isEmpty()) {
        spansBuilder.add(Collections.singleton(className), length);
      }
    }
  } catch (IOException e) {
    // Ignoring JSON parsing exception in the context of
    // syntax highlighting
  }

  return spansBuilder.create();
}
```

And if we run it... 

![Highlighting of JSON Properties is not correct](/assets/2020-12-12-json-editor-with-richtextfx-part-2/fail.png)

Uh oh. Not quite what we expected... So what happened here? 

Did you notice when we add a [`StyleSpan`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/model/StyleSpan.html) to the builder we only specify the length of the span, not where it starts.

The thing is: **Style Spans need to be contiguous from start to finish.** 

In order to do so we can track the last highlighted car, and fill in the blanks if needed. 

Replace in the previous snippet to add spans of non styled text:
```java
String className = jsonTokenToClassName(jsonToken);
if (!className.isEmpty()) {
    int start = (int) parser.getTokenLocation().getCharOffset();
    // Fill the gaps, since Style Spans need to be contiguous.
    if(start > lastPos)
    {
        int noStyleLength = start - lastPos;
        spansBuilder.add(Collections.emptyList(), noStyleLength);
    }
    lastPos = start + length;

    spansBuilder.add(Collections.singleton(className), length);
}
```

Let's run it again.

![Highlighting of JSON is now correct](/assets/2020-12-12-json-editor-with-richtextfx-part-2/success.png)

It looks like we got it right this time 👍

[Free tech tip](https://www.youtube.com/c/LinusTechTips): You can also add the following to avoid an error in case of an empty JSON document:

```java
if(lastPos == 0) {
  spansBuilder.add(Collections.emptyList(), code.length());
}
```

A slightly different implementation is available in my [100-days-of-javafx GitHub repository](https://github.com/Leward/100-days-of-javafx/blob/main/json-schema-manager/src/main/java/eu/leward/jschema/highlighting/Json.java).

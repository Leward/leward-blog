---
layout:     post
title:      "JSON Editor with RichTextFX (part 1)"
slug:       json-editor-with-richtextfx-part-1
date:       2020-12-08 23:32:00 -0400
categories: 100-days-javafx
lang:       en
ref:        json-editor-with-richtextfx-part-1
excerpt_separator: <!--more-->
---

Editing a JSON Schema is editing a JSON document. And editing a JSON document as akin to editing code (-ish).

The [`TextArea`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/TextArea.html) control provided by JavaFX is a bit limited to support a good code editing experience. 

Hopefully there is a library we can use to help us out by providing a TextArea on steroids: [RichTextFX](https://github.com/FXMisc/RichTextFX).

<!--more-->

## Replace basic TextArea with RichTextFX

As described by the authors of the library:

> [RichTextFX](https://github.com/FXMisc/RichTextFX) provides a memory-efficient text area for JavaFX that allows the developer to style ranges of text, display custom objects in-line (no more HTMLEditor), and override the default behavior only where necessary without overriding any other part of the behavior.

RichTextFX is a good base to build code editors in JavaFX.

To use it, add the following dependency to your `pom.xml` file.

```xml
<dependency>
  <groupId>org.fxmisc.richtext</groupId>
  <artifactId>richtextfx</artifactId>
  <version>0.10.5</version>
</dependency>
```

For a modular project don't forget to add `requires org.fxmisc.richtext;` to your `module-info.java`.

The library offers a [`CodeArea`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/CodeArea.html) control with default configuration supporting a code editor use case such as:

- Undo
- Select word logic to include underscrores
- Uses fixed-width font by default

To use it first, replace the exiting TextArea in the FXML file:

```xml
<?import org.fxmisc.richtext.CodeArea?>
<!-- (...) -->
<CodeArea fx:id="schemaEditor" />
```

And in the Controller Class: 

```java
public class EditingPane extends TabPane {
  @FXML private CodeArea schemaEditor;

  public EditingPane() {
    EasyBind.monadic(schema)
        .selectProperty(Schema::rawProperty)
        .addListener((observable, oldValue, newValue) -> schemaEditor.replaceText(0, schemaEditor.getLength(), newValue));
  }
}
```

![Using a "basic CodeArea"](/assets/2020-12-08-json-editor-with-richtextfx-part-1/uncolored-codearea.png)

_`CodeArea` is used without much customization instead of `TextArea`_

## How to apply styling to the text with RichTextFX

So far the CodeEditor does not change much from our previous TextArea. One of the main benefit of using RichTextFX is the ability to style the content of the text editing zone.

Using [`CodeArea`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/CodeArea.html) allows us to apply style using CSS classes. Let's try with a first basic example by colouring the text in red.

First, we need a CSS file.

```css
/* src/main/resources/style.css */
.red-text {
    -fx-fill: red;
}
```

And load the CSS.

```java
public class App extends Application {
  @Override
  public void start(Stage stage) throws Exception {
    // Setup the Scene
    // (...)
    
    // Configure CSS
    URL cssResource = App.class.getResource("/style.css");
    scene.getStylesheets().add(cssResource.toExternalForm());

    stage.show();
  }
}
```

Because we are working with a code editor, styling needs to be updating as we type. We can listen the ["text" property of the `CodeArea`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/GenericStyledArea.html#textProperty--).

```java
codeArea.textProperty().addListener((obs, oldText, newText) -> {
  codeArea.setStyleSpans(0, computeHighlighting(codeArea.getText()));
});
```

I've made a computeHighlighting method to create the styling to be applied. Styling works by applying a list of [`StyleSpan`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/model/StyleSpan.html). We can use [`StyleSpanBuilder`](http://fxmisc.github.io/richtext/javadoc/0.10.5/org/fxmisc/richtext/model/StyleSpansBuilder.html) to help us with this task.

```java
private static StyleSpans<Collection<String>> computeHighlighting(String text) {
  StyleSpansBuilder<Collection<String>> spansBuilder = new StyleSpansBuilder<>();
  return spansBuilder.create();
}
```

When applying a style with the `StyleSpanBuilder`, you specifythe styles to apply and the number of chars this applies to:

```java
private static StyleSpans<Collection<String>> computeHighlighting(String text) {
  StyleSpansBuilder<Collection<String>> spansBuilder = new StyleSpansBuilder<>();
  spansBuilder.add(List.of("red-text"), text.length() / 2);
  return spansBuilder.create();
}
```

![Styling applied to the CodeArea"](/assets/2020-12-08-json-editor-with-richtextfx-part-1/colored-codearea.png)

_Half of the JSON document is colored in red, as expected._

Styling of the text editor is exactly what we need to apply syntax highlighting on our JSON Schema. This is what we will see in the next post.
---
layout:     post
title:      "Editable ListView Cells in JavaFX"
slug:       editable-listview-cells-in-javafx
date:       2020-12-05 02:53:00 -0400
categories: 100-days-javafx
lang:       en
ref:        editable-listview-cells-in-javafx
excerpt_separator: <!--more-->
---

Following up on the [previous article on ListView and Observable Collections]({% post_url 2020-12-03-EN-observable-collection-and-listview-in-javafx %}), we want to use it in our JSON Schema Editor project with the ability to edit the name of the schema.

Let's explore how we can use [`TextFieldListCell`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/cell/TextFieldListCell.html) for this purpose.

<!--more-->

## Using the built-in TextFieldListCell

JavaFX provides out of the box with a mechanism to have ListView cells with are editable by using a [`TextFieldListCell`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/cell/TextFieldListCell.html).

```java
public class Demo2 extends Application {
    @Override
    public void start(Stage stage) throws Exception {
        ObservableList<String> items = FXCollections.observableArrayList("a", "b", "c");

        StringConverter<String> converter = new DefaultStringConverter();
        ListView<String> listView = new ListView<>(items);
        listView.setEditable(true);
        listView.setCellFactory(param -> new TextFieldListCell<>(converter));

        Scene scene = new Scene(listView, 640, 480);
        stage.setScene(scene);
        stage.show();
    }
}
```

![Simple Editable Cells](/assets/2020-12-05-editable-listview-cells-in-javafx/simple-editable-listview.png)

[`TextFieldListCell`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/cell/TextFieldListCell.html) works great for scalar values or simple value objects (such as [Currency](https://openjfx.io/javadoc/15/javafx.base/javafx/util/converter/CurrencyStringConverter.html)). However it will not play well with our previous example where we listed Schema objects composed of a name (that we want to edit) and a JSON Schema as a String.

A TextFieldListCell needs a [StringConverter](https://openjfx.io/javadoc/15/javafx.base/javafx/util/StringConverter.html) object in order to transform the string the user typed into the object type we desire to use.

```java
public static class Converter extends StringConverter<Schema> {
    @Override
    public String toString(Schema schema) {
        return schema.getName();
    }

    @Override
    public Schema fromString(String string) {
        return new Schema(string, "");
    }
}
```

When converting a string to a Schema, we can only fill the name of the Schema and [`TextFieldListCell`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/cell/TextFieldListCell.html)  will replace the existing Schema in the list with the one it created, effectively some data along the way.

## Extend TextFieldListCell and Rebuild the Converter

The main problem with the earlier approach is: The [StringConverter](https://openjfx.io/javadoc/15/javafx.base/javafx/util/StringConverter.html) always create a new `Schema` instance and only fill its name, losing existing data in the process.

We could have the converter try to reusing the current schema object. However, since we created the converter beforehand it.

The trick is to have the converter re-created whenever a new schema instance is assigned to the cell by overriding the [`updateItem`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/Cell.html#updateItem(T,boolean)) method.

```java
package eu.leward.jschema;

import javafx.scene.control.cell.TextFieldListCell;
import javafx.util.StringConverter;

public class SchemaListCell extends TextFieldListCell<Schema> {

    public SchemaListCell() {
        super();
        refreshConverter();
    }

    private void refreshConverter() {
        StringConverter<Schema> converter = new StringConverter<>() {
            @Override
            public String toString(Schema schema) {
                return schema.getName();
            }

            @Override
            public Schema fromString(String string) {
                if (isEmpty()) {
                    return new Schema(string, "{}");
                }
                Schema schema = getItem();
                schema.setName(string);
                return schema;
            }
        };
        setConverter(converter);
    }

    @Override
    public void updateItem(Schema item, boolean empty) {
        super.updateItem(item, empty);
        refreshConverter();
    }
}
```

![Custom ListCell in Action](/assets/2020-12-05-editable-listview-cells-in-javafx/demo.webp)

With this approach we can leverage any class of our choosing with [`TextFieldListCell`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/cell/TextFieldListCell.html).
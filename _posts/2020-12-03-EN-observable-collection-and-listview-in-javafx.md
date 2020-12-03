---
layout:     post
title:      "Observable Collections and ListView in JavaFX"
slug:       observable-collection-and-listview-in-javafx
date:       2020-12-03 00:39:00 -0400
categories: 100-days-javafx
lang:       en
ref:        observable-collection-and-listview-in-javafx
excerpt_separator: <!--more-->
---

In [a previous example]({% post_url 2020-11-23-EN-demo-app-from-fxml-static-to-dynamic %}) we used a [`TreeView`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/TreeView.html) to represent our list of schema. However, our Schema model does not follow a tree-like structure. 

A schema stands on its own and does not have any parent or children. Therefore, a TreeView is not the best fit to render it. Instead we should be using a [`ListView`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/ListView.html).

Let's see how we can leverage List Views with [JavaFX Observable Collections](https://openjfx.io/javadoc/15/javafx.base/javafx/collections/package-summary.html).

<!--more-->

## Introduction to Observable Collections

If you are familar with Java, you should familiar with its collection types: `Set`, `List`, `Map`, etc. 

An Observable Collection is a collections whose changes can be listened to. In that regard it is similar to the JavaFX properties.

- Scalar Value (String, Integer, etc. ) → Propery
- Java Collection → Observable Collection (such as [`ObservableList`](https://openjfx.io/javadoc/15/javafx.base/javafx/collections/ObservableList.html))

While you can implement listeners yourself on these collections, they also play well with some JavaFX controls such as `ListView`. A list view is a list of visual elements (`ListCell`) which is repeated based on a provided list of items.

When creating a `ListView` it is possible to provide a vanilla Java collection. However you will get the most out of it by using an Observable Collection.

```java
ObservableList<Schema> schemas = FXCollections.observableArrayList();

ListView<Schema> listView = new ListView(schemas);

// Any change you do later to the collection will be reflected in the List View
schemas.add(new Schema("a", "{}"));
schemas.add(new Schema("b", "{}"));
```

![Simple ListView Example](/assets/2020-12-03-observable-collection-and-listview-in-javafx/listview-1.png)

By adding a button to the schema that append a new Schema to the list, the ListView will update automatically:

```java
Button btn = new Button("Click me");
btn.setOnAction(event -> schemas.add(new Schema("c", "{}")));
```

![ListView synced with the Observable Collection](/assets/2020-12-03-observable-collection-and-listview-in-javafx/listview-2.png)

_The ListView is synced with the ObservableCollection, adding a schema the observable collection make it appear in the UI._

## Customize ListView rendering using ListCell and CellFactory

Each item in the list is actually a node of type [`ListCell`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/ListCell.html). For a simple text-only cell, the `ListView` control takes care of it for us.

However we can take control over how each cell renders, making the `ListView` a very powerful component.

We want on each row:

- to show the schema name
- to show a button. When click, it'll add "!" to the schema name

Let's design our cell.

```java
public class SchemaListCell extends ListCell<Schema> {

    private HBox container;
    private Label label;
    private Button button;

    public SchemaListCell() {
        label = new Label();
        button = new Button("Add !");
        container = new HBox(label, button);

        button.setOnAction(event -> {
            if(!isEmpty()) {
                Schema schema = getItem();
                schema.setName(schema.getName() + "!");
            }
        });
    }

    @Override
    protected void updateItem(Schema item, boolean empty) {
        super.updateItem(item, empty);
        if (empty) {
            label.textProperty().unbind();
            label.setText("");
        } else {
            label.textProperty().bind(item.nameProperty());
        }
        setGraphic(container);
    }
}
```

We have two method to look for here:

- The **constructor** sets up the graphical elements (Nodes) which compose the UI of the Cell.
- The **update** method is JavaFX telling to initialize the cell with a Schema object.

When we create a ListView, we let the control create the Cell. Whenever the ListView wants to set, change or remove a value on a ListCell object, it will call the update method.

**ListView can (and will) reuse existing ListCell instances and create empty instances!**

This is why on the update method and the button callback, we need to check wether this is an empty cell or not.

Lastly, we need to instruct the ListView how it should create cells. In this case we want it to use our custom `SchemaListCell` class.

```java
ListView<Schema> listView = new ListView<>(schemas);
listView.setCellFactory(param -> new SchemaListCell());
```

![Custom ListCell in Action](/assets/2020-12-03-observable-collection-and-listview-in-javafx/listview-animated.webp)

_Custom List Cells playing nicely with our observable collection and databinding on the Schema name._

As highlighted earlier, we notice that indeed `ListView` creates empty Cell. I did not hide the button when the cell is empty to make this behaviour more apparant.

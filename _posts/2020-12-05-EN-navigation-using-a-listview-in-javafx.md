---
layout:     post
title:      "Navigation using a ListView in JavaFX"
slug:       navigation-using-a-listview-in-javafx
date:       2020-12-05 21:43:00 -0400
categories: 100-days-javafx
lang:       en
ref:        navigation-using-a-listview-in-javafx
excerpt_separator: <!--more-->
---

The [Schema Editor app]({% post_url 2020-11-14-EN-new-project-json-schema-app %}) I've been working on has two main panes in its UI: the menu on the left and the editor and the center.

In the previous posts we were able to [create a reactive menu]({% post_url 2020-12-03-EN-observable-collection-and-listview-in-javafx %}) and [make the name of the schema editable]({% post_url 2020-12-05-EN-editable-listview-cells-in-javafx %}).

<!--more-->

![The Application after it started](/assets/2020-12-05-navigation-using-a-listview-in-javafx/app.png)

## React when an Schema is selected in the ListView

We want the editor view to reflect the correct schema when selecting the schema from the ListView.

This not something you can do in FXML. However you can get a property that tracks the currently selected item: [`listView.getSelectionModel().selectedItemProperty()`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/SelectionModel.html#selectedItemProperty())

```java
public class AppController {
    @FXML private ListView<Schema> schemaListView;
    @FXML private TextArea schemaEditor;

    private final ObjectProperty<Schema> selectedSchemaProperty 
        = new SimpleObjectProperty<>();

    @FXML
    public void initialize() throws IOException {
        ObservableList<Schema> schemas = FXCollections.observableArrayList();
        schemaListView.setEditable(true);
        schemaListView.setCellFactory(param -> new SchemaListCell());
        schemaListView.setItems(schemas);

        selectedSchemaProperty.bind(schemaListView.getSelectionModel().selectedItemProperty());
        selectedSchemaProperty.addListener((observable, oldValue, newValue) -> {
            schemaEditor.setText(newValue.getRaw());
        });

        // Load data
        InitialDataLoader dataLoader = new InitialDataLoader();
        schemas.addAll(dataLoader.load());
    }
}
```

Don't forget to add `fx:id="schemaEditor"` to the TextArea in the .fxml file.

![Textarea updates based on the selected item in the ListView](/assets/2020-12-05-navigation-using-a-listview-in-javafx/demo.webp)

_Textarea updates based on the selected item in the ListView._

## Using EasyBind

I worked in the past with [RxJava](https://github.com/ReactiveX/RxJava) which also have a type called [Observable](http://reactivex.io/RxJava/3.x/javadoc/io/reactivex/rxjava3/core/Observable.html) (its sematic varies from the JavaFX Observable though). One of the thing that I enjoy was possibility to use function such as [`.map()`](http://reactivex.io/RxJava/3.x/javadoc/io/reactivex/rxjava3/core/Observable.html#map-io.reactivex.rxjava3.functions.Function-) to transform an observable.

While the [Bindings](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/binding/Bindings.html) util class offers some tools to do transformation of observables, I am not found of its ergonomics. I prefer to use the [EasyBind](https://github.com/TomasMikula/EasyBind) library instead:

```java
// When the selected schema changes
selectedSchemaProperty.bind(schemaListView.getSelectionModel().selectedItemProperty());
schemaEditor.textProperty().bind(
    EasyBind.monadic(selectedSchemaProperty)
        .selectProperty(Schema::rawProperty)
);
```

I could skip using the `selectedSchemaProperty` variable altogether:

```java
// When the selected schema changes
schemaEditor.textProperty().bind(
    EasyBind.monadic(schemaListView.selectionModelProperty())
        .flatMap(SelectionModel::selectedItemProperty)
        .selectProperty(Schema::rawProperty)
);
```

_Don't forget to add the esybind dependency to your `pom.xml` and `module-info.java` files._

I'm a big fan of monads as they allow to make my code linear, hence easier to read.
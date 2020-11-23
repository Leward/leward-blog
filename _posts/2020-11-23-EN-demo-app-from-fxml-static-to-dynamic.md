---
layout:     post
title:      "Demo App: From FXML static content to dynamic content"
slug:       demo-app-from-fxml-static-to-dynamic
date:       2020-11-23 00:04:00 -0400
categories: 100-days-javafx
lang:       en
ref:        demo-app-from-fxml-static-to-dynamic
excerpt_separator: <!--more-->
---

In [the previous post]({% post_url 2020-11-08-EN-build-favafx-native-executable-fxml %}), we created a static and basic UI to kickstart our JSON Schema Manager project. One the first things we want to do is to make it dynamic based on data that we define. Later on, we will let the user update the data.

<!--more-->

## Model

```java
public class Schema {

    private String name;
    private String raw;

    public Schema(String name, String raw) {
        this.name = name;
        this.raw = raw;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getRaw() {
        return raw;
    }

    public void setRaw(String raw) {
        this.raw = raw;
    }
}
```

For now, let's keep things simple by having the JSON Schema as a raw String. We will figure out later how to parse it order to display a GUI to edit the schema — instead of using a single text area.

## Initial Data

Let's make a class whose responsibility will be to load initial data when the application starts.

```java
public class InitialDataLoader {
  public List<Schema> load() throws IOException {
    Schema person = new Schema("person", loadExampleFile("person.schema.json"));
    Schema geo = new Schema("geo", loadExampleFile("geo.schema.json"));
    return List.of(person, geo);
  }

  private String loadExampleFile(String fileName) throws IOException {
    return new String(
      getClass().getResource("/examples/" + fileName)
        .openStream()
        .readAllBytes()
    );
  }
}
```

Those `*.schema.json` files live under the `src/main/resources/examples` directory. The examples files are considered to be part of the application and not from the regular user's file system.

## Load Initial Data from the Controller

Now that we have a way to load some data, let's have it work with out FXML Controller.

```java
public class AppController {
    @FXML
    public void initialize() throws IOException {
        InitialDataLoader dataLoader = new InitialDataLoader();
        List<Schema> schemas = dataLoader.load();
    }
}
```

An `initialize()` method annotated with `@FXML` will be executed when FXML is initializing the constructor and has injected all the attributes annotated with `@FXML`.

> FXMLLoader will now automatically call any suitably annotated no-arg initialize() method defined by the controller.
— [Initializable JavaDoc](https://openjfx.io/javadoc/15/javafx.fxml/javafx/fxml/Initializable.html)

You can have some custom class initialization logic in the constructor, but that logic will not be able to interact with JavaFX bindings are resources the controller is attached to.

## Replace the static TreeView content

We have some data in the controller, we can now use the controller to interact with the FXML defined view.

To be able to interact with the root the TreeView, it is needed to assign it an ID:

```xml
<TreeView>
    <TreeItem value="Schemas" expanded="true" fx:id="schemasTreeRoot">
        <children>
            <TreeItem value="event.json"/>
            <TreeItem value="game.json"/>
        </children>
    </TreeItem>
</TreeView>
```

Make sure the corresponding attribute in the controller has the same name as the FXML ID.

```java
public class AppController {
  @FXML
  private TreeItem<String> schemasTreeRoot;

  @FXML
  public void initialize() throws IOException {
    // Load data
    InitialDataLoader dataLoader = new InitialDataLoader();
    List<Schema> schemas = dataLoader.load();

    // Replace TreeView content with loaded data
    schemasTreeRoot.getChildren().clear();
    schemas.stream()
      .map(schema -> new TreeItem<String>(schema.getName()))
      .forEach(stringTreeItem -> schemasTreeRoot.getChildren().add(stringTreeItem));
  }
}
```

![Demo](/assets/2020-11-23-demo-app-from-fxml-static-to-dynamic/demo.png)

This works great for the initial data load, what if we add new schema or we rename one? 

In the next article we will explore how to react to changes, and have our UI updating based on changes made on the data.
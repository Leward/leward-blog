---
layout:     post
title:      "Extract JavaFX Component (FXML)"
slug:       extract-javafx-component-fxml
date:       2020-12-05 21:43:00 -0400
categories: 100-days-javafx
lang:       en
ref:        extract-javafx-component-fxml
excerpt_separator: <!--more-->
---

Until now, we been using a single FXML with a single controller and have put our components and logic in there. 

However as the application grows in complexity, the single controller and FXML file does not work so great in term maintenance. We want smaller pieces which are easier to work with in order to avoid the complexity to creep out of control.

<!--more-->

![Annotated app screenshot](/assets/2020-12-06-extract-javafx-component-fxml/app.png)

_We are extracting the part highlighted in the screenshot into its own Component._


## Extract TabPane FXML

Create a new FXML in `src/main/resources/editingpane.fxml`.

```xml
<?xml version="1.0" encoding="UTF-8"?>

<?import java.lang.*?>
<?import java.util.*?>
<?import javafx.scene.*?>
<?import javafx.scene.control.*?>
<?import javafx.scene.layout.*?>

<fx:root xmlns="http://javafx.com/javafx"
         xmlns:fx="http://javafx.com/fxml"
         type="javafx.scene.control.TabPane">

  <Tab text="JSON" closable="false">
    <TextArea style="-fx-font-family: 'Inconsolata'" fx:id="schemaEditor">
    </TextArea>
  </Tab>

  <Tab text="Designer" closable="false">
    <GridPane hgap="10" vgap="10" style="-fx-padding: 20px;">
      <Label text="\$id" GridPane.rowIndex="0" GridPane.columnIndex="0"/>
      <TextField text='https://example.com/person.schema.json' GridPane.rowIndex="0"
                 GridPane.columnIndex="1"/>

      <Label text="title" GridPane.rowIndex="1" GridPane.columnIndex="0"/>
      <TextField text='Person' GridPane.rowIndex="1" GridPane.columnIndex="1"/>

      <Label text="type" GridPane.rowIndex="2" GridPane.columnIndex="0"/>
      <ChoiceBox GridPane.rowIndex="2" GridPane.columnIndex="1" value="object">
        <String fx:value="object"/>
        <String fx:value="string"/>
        <String fx:value="number"/>
        <String fx:value="boolean"/>
      </ChoiceBox>
    </GridPane>
  </Tab>

  <Tab text="Examples">
    <Label text="Examples will come here"/>
  </Tab>

</fx:root>
```

## EditingPane Class for our new Component

Our new component (EditingPane) is a specialized [`TabPane`](https://openjfx.io/javadoc/15/javafx.controls/javafx/scene/control/TabPane.html).

```java
public class EditingPane extends TabPane {

  @FXML private TextArea schemaEditor;

  final private ObjectProperty<Schema> schema = new SimpleObjectProperty<>();

  public EditingPane() {
    URL fxmlResource = EditingPane.class.getResource("/editingpane.fxml");
    FXMLLoader fxmlLoader = new FXMLLoader(fxmlResource);
    fxmlLoader.setRoot(this);
    fxmlLoader.setController(this);

    try {
      fxmlLoader.load();
    } catch (IOException e) {
      // Component is broken, not much that can be recovered from.
      throw new RuntimeException(e);
    }

    schemaEditor.textProperty().bind(
      EasyBind.monadic(schema).selectProperty(Schema::rawProperty)
    );
  }

  public Schema getSchema() {
    return schema.get();
  }

  public ObjectProperty<Schema> schemaProperty() {
    return schema;
  }

  public void setSchema(Schema schema) {
    this.schema.set(schema);
  }
}
```

Reminder: We started using [EasyBind](https://github.com/TomasMikula/EasyBind) in [an earlier post]({% post_url 2020-12-05-EN-navigation-using-a-listview-in-javafx %}) to transform properties.

## Use the new EditingPane Component

Changes in `app.fxml`:

 - A new import is added in order to be able to use the new `EditingPane` control
 - The whole `<TabPane></TabPane>` is replaced with `<EditingPane fx:id="editingPane" />`

```xml
<!-- app.fxml -->

<?xml version="1.0" encoding="UTF-8"?>

<?import eu.leward.jschema.EditingPane?>
<?import javafx.scene.control.ListView?>
<?import javafx.scene.layout.BorderPane?>

<BorderPane xmlns="http://javafx.com/javafx"
            xmlns:fx="http://javafx.com/fxml"
            fx:controller="eu.leward.jschema.AppController"
            prefHeight="400.0" prefWidth="600.0">

  <left>
    <ListView fx:id="schemaListView"/>
  </left>

  <center>
    <EditingPane fx:id="editingPane"/>
  </center>

</BorderPane>
```

Changes in `AppController`:

 - The controller does not interect with the TextArea, but with the new EditingPane component instead
 - Since EditingPane has a `schema` property, we can bind it with `selectedSchemaProperty` directly. 

```java
public class AppController {
  @FXML private ListView<Schema> schemaListView;
  @FXML private EditingPane editingPane;

  private final ObjectProperty<Schema> selectedSchemaProperty = new SimpleObjectProperty<>();

  @FXML
  public void initialize() throws IOException {
    ObservableList<Schema> schemas = FXCollections.observableArrayList();
    schemaListView.setEditable(true);
    schemaListView.setCellFactory(param -> new SchemaListCell());
    schemaListView.setItems(schemas);

    // When the selected schema changes
    selectedSchemaProperty.bind(schemaListView.getSelectionModel().selectedItemProperty());
    editingPane.schemaProperty().bind(selectedSchemaProperty);

    // Load data
    InitialDataLoader dataLoader = new InitialDataLoader();
    schemas.addAll(dataLoader.load());
  }
}
```

And... that's pretty much it.

**Grouping controls that belong together into an higher level component is a good way to manage complexity in a JavaFX application ; this applies to UI development in general.**
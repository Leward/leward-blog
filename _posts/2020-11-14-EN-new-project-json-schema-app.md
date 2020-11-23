---
layout:     post
title:      "New Project: A JavaFX App to manage JSON Schema"
slug:       new-project-json-schema-app
date:       2020-11-14 22:47:00 -0400
categories: 100-days-javafx
lang:       en
ref:        new-project-json-schema-app
excerpt_separator: <!--more-->
---

Together, we've seen how [to create basic skeleton for a JavaFX application (using FXML)]({% post_url 2020-11-14-EN-new-project-json-schema-app %}). For the next days and articles, I will be using an example project to explore the different aspects of building a JavaFX application.

The example application is a tool that offers a GUI to manage to collection of JSON Schemas. Who knows, if things go well I may even release it as a proper application. In this article we are going to layout the basics for the application UI.

<!--more-->

Some of the basic features I want to implement:

- List schema
- GUI to build and edit JSON schemas
- Examples that can be used for validation
- View and Edit the raw schema with syntax highlighting (like a regular code editor)

## FXML Elements

### Our root Node — BorderPane

```xml
<BorderPane xmlns="http://javafx.com/javafx"
            xmlns:fx="http://javafx.com/fxml"
            fx:controller="eu.leward.jschema.AppController"
            prefHeight="400.0" prefWidth="600.0">

  <left> <!-- Content of the left pane --> </left>
  <center> <!-- Content of the center pane --> </center>

</BorderPane>
```

A BorderPane sets 5 region which can are anchored to different areas of the screen.

![Border Pane](/assets/2020-11-14-new-project-json-schema-app/borderpane.png)

_BorderPane example from the [OpenJFX API Documentation](https://openjfx.io/javadoc/15/javafx.graphics/javafx/scene/layout/BorderPane.html)_

For our app, we will be only using, for now, the left and center areas.

### Listing (Explorer) the JSON Schema — TreeView

```xml
<TreeView>
    <TreeItem value="Schemas" expanded="true">
        <children>
            <TreeItem value="event.json"/>
            <TreeItem value="game.json"/>
        </children>
    </TreeItem>
</TreeView>
```

![Tree View](/assets/2020-11-14-new-project-json-schema-app/treeview.png)

_TreeView example_

### Our tabbed main view — TabPane

```xml
<TabPane>
    <Tab text="JSON" closable="false">
       <!-- Content Here -->
    </Tab>
    <Tab text="Designer" closable="false">
        <!-- Content Here -->
    </Tab>
    <Tab text="Examples">
        <Label text="Examples will come here"/>
    </Tab>
</TabPane>
```

![Tab Pane](/assets/2020-11-14-new-project-json-schema-app/tabpane.png)

_TabPane example_

### A GridPane for the Designer Form

GridView allows you to organize the layout of your elements following a grid. It's very similar to how HTML tables were used back in the days.

GridPane is very useful to align elements of a form.

```xml
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
```

Pay a close attention to the `**GridPane.rowIndex**` and `**GriPane.columnIndex**` attributes. Those are the attributes you use to define your grid. Unlike HTML you don't how have to explicitly create tags for rows and cells, the GridView components will figure that out for you. This is somewhat similar to CSS Grids.

GridPane has more options to it, but we keep it simple here since that's all we need.

![Grid Pane](/assets/2020-11-14-new-project-json-schema-app/gridpane.png)

_GridPane example_

## Full FXML Example

```xml
<!-- app.fxml -->
<?xml version="1.0" encoding="UTF-8"?>

<?import java.lang.*?>
<?import java.util.*?>
<?import javafx.scene.*?>
<?import javafx.scene.control.*?>
<?import javafx.scene.layout.*?>

<?import javafx.collections.FXCollections?>
<BorderPane xmlns="http://javafx.com/javafx"
            xmlns:fx="http://javafx.com/fxml"
            fx:controller="eu.leward.jschema.AppController"
            prefHeight="400.0" prefWidth="600.0">

    <left>
        <TreeView>
            <TreeItem value="Schemas" expanded="true">
                <children>
                    <TreeItem value="event.json"/>
                    <TreeItem value="game.json"/>
                </children>
            </TreeItem>
        </TreeView>
    </left>

    <center>
        <TabPane>
            <Tab text="JSON" closable="false">
                <TextArea style="-fx-font-family: 'Inconsolata'">
                    { "$id": "https://example.com/person.schema.json" }
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
        </TabPane>
    </center>

</BorderPane>
```

![JSON Editor Tab](/assets/2020-11-14-new-project-json-schema-app/full-tab1.png)


_JSON Editor Tab_

![Schema Designer Tab](/assets/2020-11-14-new-project-json-schema-app/full-tab2.png)

_JSON Designer Tab_

![Example Tab](/assets/2020-11-14-new-project-json-schema-app/full-tab1.png)

_Examples tab — not much is there yet_
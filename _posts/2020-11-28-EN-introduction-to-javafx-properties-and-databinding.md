---
layout:     post
title:      "Introduction to Properties and Databinding in JavaFX"
slug:       introduction-to-javafx-properties-and-databinding
date:       2020-11-28 01:44:00 -0400
categories: 100-days-javafx
lang:       en
ref:        introduction-to-javafx-properties-and-databinding
excerpt_separator: <!--more-->
---

In the previous article we made a Schema model class a simple [Java Bean](https://stackoverflow.com/questions/3295496/what-is-a-javabean-exactly). We did not exactly follow all the rules for a Java bean but what mattered was to have private attributes with getters and setters. To make the model work nicely with JavaFX we need to make it a JavaFX Bean.

<!--more-->

## From Java Bean to JavaFX Bean

How does JavaFX Bean differ from your traditional Java Bean? 
Like for java Beans, the concept of JavaFX Bean is a convention:

- Its attributes use "Property" types instead of basic types (`IntegerProperty` instead of `int` or `Integer`)
- Its property attributes are final — the value inside the property changes, not the property instance itself
- Getters will read inside the property: `age.getValue();`
- Setters will write inside the property: `age.setValue();`
- Exposes its property: `public IntegerProperty ageProperty() { }`

## The Property Interface

Its basic building blocks are:

- *(Interface)* [ObservableValue](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/value/ObservableValue.html)
*— an entity that wraps content and allows to observe the content for invalidations*
- *(Interface)* [WritableValue](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/value/WritableValue.html)
*— an entity that wraps a value that can be read and set*

**A Property is a a wrapped writeable value whose changes can be observed.**

## Property class hierarchy

A simply view of the hierarchy of classes and interfaces available to define an Integer Property. In bold are the ones you are the most likely to be using.

- *(Interface)* [Property](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/property/Property.html)
    - *(Abstract)* [IntegerProperty](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/property/IntegerProperty.html)
        - *(Abstract)* [IntegerPropertyBase](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/property/IntegerPropertyBase.html)
            - *(Abstract)* [StylableIntegerProperty](https://openjfx.io/javadoc/15/javafx.graphics/javafx/css/StyleableIntegerProperty.html)
                - **[SimpleStylableProperty](https://openjfx.io/javadoc/15/javafx.graphics/javafx/css/SimpleStyleableIntegerProperty.html)**
            - **[SimpleIntegerProperty](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/property/SimpleIntegerProperty.html)**
                - **[ReadOnlyIntegerWrapper](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/property/ReadOnlyIntegerWrapper.html)**
    - JavaBeanIntegerProperty

## Code Examples

A property is a container for a value that can change over time.

```java
IntegerPropery a = new SimpleIntegerProperty(1);
a.setValue(2);
a.setValue(3);
```

We change the value inside of a, but always points to the same instance of IntegerPropery. Property fields can usually be final because they won't need to change.

```java
final IntegerPropery a = new SimpleIntegerProperty(1);
a.setValue(2); // Will work
```

The main benefit of this approach is that we can more easily track value changes.

```java
IntegerProperty a = new SimpleIntegerProperty(1);
a.addListener((observable, oldValue, newValue) -> {
  System.out.printf("Value changed from %d to %d %n", oldValue.intValue(), newValue.intValue());
});
a.setValue(2);
a.setValue(3);

// Will print:
// Value changed from 1 to 2 
// Value changed from 2 to 3
```

A property has the concept of binding, that is having the value of a property following another.

```java
IntegerProperty a = new SimpleIntegerProperty(1);

IntegerProperty b = new SimpleIntegerProperty(0);
b.bind(a);
b.addListener((observable, oldValue, newValue) -> {
  System.out.printf("Value changed from %d to %d %n", oldValue.intValue(), newValue.intValue());
});

a.setValue(2);
a.setValue(3);

// Will print:
// Value changed from 1 to 2 
// Value changed from 2 to 3
```

In this example, we listen on b, but are performing the changes on a. Because b is bound to a, changes from a are propagated to b.

## Binding and Property Are Two Different Things

JavaFX have a different interface for [Property](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/property/Property.html) and [Binding](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/binding/Binding.html):

- (Interface) [ObservableValue](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/value/ObservableValue.html)
    - (Interface) [Property](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/property/Property.html)
    - (Interface) [Binding](https://openjfx.io/javadoc/15/javafx.base/javafx/beans/binding/Binding.html)

Unlike a property, you can't set an arbitrary value to a binding. Bindings only react to what it is bound to by performing a predetermined transformation.

In the next example, the `multiple` method allows us to define a binding to our property and transform it by multiplying the value by a number.

```java
IntegerProperty a = new SimpleIntegerProperty(1);
IntegerBinding b = a.multiply(2);

b.addListener((observable, oldValue, newValue) -> {
  System.out.printf("Value changed from %d to %d %n", oldValue.intValue(), newValue.intValue());
});

a.setValue(2);
a.setValue(3);

// Will print:
// Value changed from 2 to 4 
// Value changed from 4 to 6
```

**Properties and binding are key elements that will allow to make our UI more dynamic.**
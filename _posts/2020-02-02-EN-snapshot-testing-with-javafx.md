---
layout:     post
title:      "Snapshot Testing with JavaFX"
slug:       snapshot-testing-with-javafx
date:       2020-02-02 17:29:00 +0800
categories:
lang:       en
ref:        snapshot-testing-with-javafx
excerpt_separator: <!--more-->
---

A few months ago, I was doing some iOS development and got to discover a way to test the rendering of UIs: Snapshot testing. The premise is that regular Unit or End-to-End tests don't do a great job at testing how the app renders.

Snapshot Testing is a technique where you don't rely on usual assertions. Instead, you validate, as a human, how the app renders (the snapshot) and save it alongside the source code. Unless you expect a visual difference in you screen, the snapshot should remain the same.

<!--more-->

Since I decided to take back on some JavaFX, I decided to apply the same technique on my JavaFX work.

# Taking a Snapshot

The following snippet shows you how to take a snapshot for a given [Scene](https://openjfx.io/javadoc/13/javafx.graphics/javafx/scene/Scene.html).

```java
public static void screenshot(Scene scene, String screenshotName) throws IOException {
    var writableImage = new WritableImage((int) scene.getWidth(), (int) scene.getHeight());
    scene.snapshot(writableImage);
    BufferedImage bufferedImage = SwingFXUtils.fromFXImage(writableImage, null);
    File outfile = new File(String.format("snapshots/%s.png", screenshotName));
    ImageIO.write(bufferedImage, "png", outfile);
}
```

[![Snapshot of the Drawing Pane](/assets/2020-02-02-EN-snapshot-testing-with-javafx/drawing-pane-1.png)](/assets/2020-02-02-EN-snapshot-testing-with-javafx/drawing-pane-1.png)

_Snapshot of the Drawing Pane_

# Testing JavaFX

In this example I'll be using JUnit 5, with [TestFX](https://github.com/TestFX/TestFX) to test the JavaFX code. Note that my project is a Maven project, setup for Gradle may differ.

TestFX will take care of the setup required to run tests for JavaFX.

Something I appreciate about TestFX lies in their [README](https://github.com/TestFX/TestFX/blob/master/README.md). It has examples for different versions of Java. It also covers different test and assertion libraries. This is a great "Getting Started" experience!

## Jigsaw / Module Hiccups

Running a modular JavaFX application with Java 13 I ran into a few hiccups when running my tests.

    java.lang.IllegalAccessError: class org.testfx.toolkit.impl.ToolkitServiceImpl (in unnamed module @0x7dcf94f8) cannot access class com.sun.javafx.application.ParametersImpl (in module javafx.graphics) because module javafx.graphics does not export com.sun.javafx.application to unnamed module @0x7dcf94f8
    	org.testfx.toolkit.impl.ToolkitServiceImpl.registerApplicationParameters(ToolkitServiceImpl.java:142)

This can be "fixed" by opening the module when launching the program with `--add-exports javafx.graphics/com.sun.javafx.application=ALL-UNNAMED`.

Then I ran into a different error:

    java.lang.reflect.InaccessibleObjectException: Unable to make void fr.leward.graphdesigner.ui.drawingpane.DrawingPaneSnapshotTest.testSomething() accessible: module graph.designer.drawing.pane does not "opens fr.leward.graphdesigner.ui.drawingpane" to unnamed module @5f9b2141

Which I fixed by adding the launch option `--add-opens graph.designer.drawing.pane/fr.leward.graphdesigner.ui.drawingpane=ALL-UNNAMED`.

Later on, while implementing my `Snapshot` utility class I ran into some more trouble:

    java.lang.IllegalAccessError: 
    class fr.leward.graphdesigner.ui.drawingpane.Snapshot (in module graph.designer.drawing.pane) 
    	cannot access class javax.imageio.ImageIO (in module java.desktop) 
    	because module graph.designer.drawing.pane does not read module java.desktop

Which could be fixed by adding `--add-reads graph.designer.drawing.pane=java.desktop` to the launch options.

I can now run `mvn test`. IntelliJ integrates well with Maven and will pickup the launch options I specified in my `pom.xml` :

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-surefire-plugin</artifactId>
  <version>3.0.0-M4</version>
  <configuration>
    <argLine>
      --add-reads graph.designer.drawing.pane=java.desktop
      --add-exports javafx.graphics/com.sun.javafx.application=ALL-UNNAMED
      --add-opens graph.designer.drawing.pane/fr.leward.graphdesigner.ui.drawingpane=ALL-UNNAMED
    </argLine>
  </configuration>
</plugin>
```

# Snapshot Testing

I implemented a small utility class that allows me to save the snapshot of a scene and compare it with an earlier snapshot. 

If the two snapshot differ, the test fails and the developer can compare the two images and verify whether the change was expected or not.

Below, you can find the implementation I went with.

```java
package fr.leward.graphdesigner.ui.drawingpane;

import javafx.embed.swing.SwingFXUtils;
import javafx.scene.Scene;
import javafx.scene.image.Image;

import javax.imageio.ImageIO;
import java.io.File;
import java.io.IOException;

import static org.assertj.core.api.Assertions.fail;

public class Snapshot {

    private final Scene scene;
    private final String name;
    private final Image snapshot;

    public Snapshot(Scene scene, String name) {
        this.scene = scene;
        this.name = name;
        this.snapshot = scene.snapshot(null);
    }

    public void saveSnapshot() throws IOException {
        var bufferedImage = SwingFXUtils.fromFXImage(snapshot, null);
        ImageIO.write(bufferedImage, "png", getSnapshotFile());
    }

    public void saveDebugSnapshot() throws IOException {
        var bufferedImage = SwingFXUtils.fromFXImage(snapshot, null);
        ImageIO.write(bufferedImage, "png", getDebugSnapshotFile());
    }

    public void assertSnapshotRemainsUnchanged() {
        Image previousSnapshot = getSavedSnapshot();

        if (snapshot.getWidth() != previousSnapshot.getWidth() || snapshot.getHeight() != previousSnapshot.getHeight()) {
            fail("The two snapshots are not of the same size");
        }

        for (int x = 0; x < (int) snapshot.getWidth(); x++) {
            for (int y = 0; y < (int) snapshot.getHeight(); y++) {
                var a = snapshot.getPixelReader().getArgb(x, y);
                var b = previousSnapshot.getPixelReader().getArgb(x, y);
                if(a != b) {
                    fail("Current snapshot differs from save snapshot");
                }
            }
        }
    }

    private Image getSavedSnapshot() {
        return new Image(String.format("file:%s", getSnapshotFilePath()));
    }

    private File getSnapshotFile() {
        return new File(getSnapshotFilePath());
    }

    private String getSnapshotFilePath() {
        return String.format("snapshots/%s.png", name);
    }

    private File getDebugSnapshotFile() {
        return new File(String.format("snapshots/%s.debug.png", name));
    }
}
```

And to write a Snapshot Test:

```java
package fr.leward.graphdesigner.ui.drawingpane;

import fr.leward.graphdesigner.core.IdGenerator;
import javafx.scene.Scene;
import javafx.stage.Stage;
import org.junit.jupiter.api.Test;
import org.testfx.framework.junit5.ApplicationTest;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;

public class DrawingPaneSnapshotTest extends ApplicationTest {

	private DrawingPane drawingPane;
	private Scene scene;
	private Snapshot snapshot;

	/**
		* Will be called with {@code @Before} semantics, i. e. before each test method.
		*/
	@Override
	public void start(Stage stage) throws Exception {
		AtomicInteger nextID = new AtomicInteger(0);
		IdGenerator generator = nextID::incrementAndGet;
		drawingPane = new DrawingPane(generator);

		scene = new Scene(drawingPane, 400, 400);
		stage.setScene(scene);
	}

	@Test
	void testSnapshot() throws IOException {
		interact(() -> {
			var a = drawingPane.addNode(30, 30);
			var b = drawingPane.addNode(100, 60);
			var c = drawingPane.addNode(90, 160);

			drawingPane.addRelationship(a, b);
			drawingPane.addRelationship(b, c);

			snapshot = new Snapshot(scene, "drawing-pane-1");
		});
		// snapshot.saveSnapshot(); // Uncomment to save and register an expected change
		snapshot.saveDebugSnapshot();
		snapshot.assertSnapshotRemainsUnchanged();
	}


}
```

Note that all the JavaFX interactions have to be made from the JavaFX thread, hence the use of `interact()`.


# Links

- [Five Command Line Options To Hack The Java Module System](https://blog.codefx.org/java/five-command-line-options-hack-java-module-system/)
- [Migrate Maven Projects to Java 11](https://winterbe.com/posts/2018/08/29/migrate-maven-projects-to-java-11-jigsaw/)
- [What is Snapshot Testing?](https://sqa.stackexchange.com/questions/29696/what-is-snapshot-testing)
# mobile_system

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Widgets and Controllers in Flutter
Widgets in Flutter
Widgets are the fundamental building blocks of Flutter applications. Everything you see on the screen in a Flutter app is a widget or a combination of widgets.

Key Characteristics of Widgets:
Declarative UI: Widgets describe what their view should look like given their current configuration and state

Immutable: Widgets are immutable (can't be changed) - when you need to change the UI, you create a new widget

Composable: Simple widgets can be combined to build complex interfaces

Rebuild efficiently: Flutter's framework is optimized to only rebuild widgets that need updating

Types of Widgets:
Stateless Widgets:

Widgets that don't store any state (their properties are final)

Examples: Text, Icon, Container

Created by extending StatelessWidget

Stateful Widgets:

Widgets that can change over time (maintain state)

Examples: Checkbox, TextField, Slider

Created by extending StatefulWidget with an associated State class

Layout Widgets:

Arrange other widgets on the screen

Examples: Row, Column, Stack, ListView

Platform Widgets:

Widgets that look native to each platform (Android/iOS)

Examples: CupertinoButton (iOS-style), MaterialButton (Android-style)

Inherited Widgets:

Allow data to flow down the widget tree efficiently

Examples: Theme, MediaQuery

# Controllers in Flutter
Controllers are objects that manage the state and behavior of certain widgets. They provide a way to programmatically interact with widgets.

# Common Controllers:
# TextEditingController:

Manages the text in a TextField or TextFormField

Allows you to read, modify, and listen to text changes

Must be disposed when no longer needed

# ScrollController:

Controls scrollable widgets like ListView, GridView, SingleChildScrollView

Allows programmatic scrolling and scroll position tracking



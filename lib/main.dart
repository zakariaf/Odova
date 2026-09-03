import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

/// The placeholder root widget. EPIC-01 ships an empty, correct, gated app;
/// the theme arrives in EPIC-02 and the router in EPIC-08.
class MainApp extends StatelessWidget {
  /// Creates the placeholder root widget.
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}

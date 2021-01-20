import 'package:flutter/material.dart';
import 'dart:async';

import 'package:typeahead/typeahead.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final suggestions = [
    Suggestion(label: 'Avocado', value: 'avocado'),
    Suggestion(label: 'Banana', value: 'banana'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Typeahead(
          delay: 500,
          suggestions: suggestions,
          hintText: 'Test',
          color: Colors.white,
          textAlign: TextAlign.center,
          onChange: _onChange,
          onSelect: onSelect,
          addOptionHandler: _addOptionHandler,
        ),
      ),
    );
  }

  Future<Suggestion<String>> _addOptionHandler(String textFieldValue) async {
    return Suggestion(label: 'Cantaloupe', value: 'cantaloupe');
  }

  List<Suggestion<String>> _onChange(String textFieldValue) {
    // do something
    return null;
  }

  dynamic onSelect(String optionValue) {
    // do something
    return null;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:typeahead/typeahead.dart';

final suggestions = [
  Suggestion(label: 'Avocado', value: 'avocado'),
  Suggestion(label: 'Banana', value: 'banana'),
];

Future<Suggestion<String>> _addOptionHandler(String textFieldValue) async {
  return Suggestion(label: 'Cantaloupe', value: 'cantaloupe');
}

class TypeaheadEventHandler {
  List<Suggestion<String>> onChange(String textFieldValue) => null;
  dynamic onSelect(String optionValue) => null;
}

class MockTypeaheadEventHandler extends Mock implements TypeaheadEventHandler {}

class App extends StatelessWidget {
  final Future<Suggestion> Function(String) addOptionHandler;
  final Function onChange;
  final Function onSelect;

  App({
    this.addOptionHandler,
    this.onChange,
    this.onSelect,
  }) : super();

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
          onChange: onChange,
          onSelect: onSelect,
          addOptionHandler: addOptionHandler,
        ),
      ),
    );
  }
}

void main() {
  TypeaheadEventHandler eventHandlers;
  final duration = const Duration(milliseconds: 500);
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Typeahead - display a textfield',
    (tester) async {
      final app = App();
      await tester.pumpWidget(app);
      final textFieldFinder = find.byType(TextField);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textFieldFinder, findsOneWidget);
      expect(textField.decoration.hintText, equals('Test'));
      expect(textField.decoration.hintStyle.color, equals(Colors.white));
      expect(textField.textAlign, equals(TextAlign.center));
    },
  );

  testWidgets(
    'Typeahead - toggle list of suggestions with "addOptionHandler"',
    (tester) async {
      final app = App(addOptionHandler: _addOptionHandler);
      await tester.pumpWidget(app);

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'a');
      await tester.pump(duration);
      expect(find.byType(ListTile), findsNWidgets(3));

      final textField = tester.widget<TextField>(textFieldFinder);
      textField.focusNode.unfocus();
      await tester.pump(duration);
      expect(find.byType(ListTile), findsNWidgets(0));
    },
  );

  testWidgets(
    'Typeahead - toggle list of suggestions without "addOptionHandler"',
    (tester) async {
      final app = App();
      await tester.pumpWidget(app);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(duration);
      expect(find.byType(ListTile), findsNWidgets(2));

      final textField = tester.widget<TextField>(find.byType(TextField));
      textField.focusNode.unfocus();
      await tester.pump(duration);
      expect(find.byType(ListTile), findsNWidgets(0));
    },
  );

  testWidgets(
    'Typeahead - emit TextField value on change event',
    (tester) async {
      eventHandlers = MockTypeaheadEventHandler();
      final app = App(onChange: eventHandlers.onChange);
      await tester.pumpWidget(app);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(duration);
      verify(eventHandlers.onChange('a')).called(1);
    },
  );

  testWidgets(
    'Typeahead - tapping a suggestion should update the text field value, '
    'call the onSelect function, '
    'and hide/remove the overlay entry',
    (tester) async {
      eventHandlers = MockTypeaheadEventHandler();
      when(eventHandlers.onChange('a')).thenReturn(suggestions);
      final app = App(
        onChange: eventHandlers.onChange,
        onSelect: eventHandlers.onSelect,
      );
      // display both suggestions
      await tester.pumpWidget(app);
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'a');
      await tester.pump(duration);
      final listTileFinder = find.byType(ListTile);
      expect(listTileFinder, findsNWidgets(2));

      // tap first suggestion to update the text field, hide the overlay entry,
      // and call onSelect
      await tester.tap(listTileFinder.first);
      final textField = tester.widget<TextField>(textFieldFinder);
      await tester.pumpAndSettle(duration);
      expect(textField.controller.text, equals('Avocado'));
      expect(textField.focusNode.hasFocus, equals(false));
      expect(listTileFinder, findsNWidgets(0));
    },
  );

  testWidgets(
    'Typeahead - tapping "add option" tile should call addOptionHandler',
    (tester) async {
      eventHandlers = MockTypeaheadEventHandler();
      when(eventHandlers.onChange('a')).thenReturn(suggestions);
      final app = App(
        addOptionHandler: _addOptionHandler,
        onChange: eventHandlers.onChange,
        onSelect: eventHandlers.onSelect,
      );

      // typing Cantaloupe will display 'Add "Cantaloupe"' button
      await tester.pumpWidget(app);
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'Cantaloupe');
      await tester.pump(duration);
      final listTileFinder = find.byType(ListTile);
      expect(listTileFinder, findsNWidgets(1));

      // tap 'Add "Cantaloupe"' button
      final textField = tester.widget<TextField>(textFieldFinder);
      await tester.tap(listTileFinder.last);
      await tester.pumpAndSettle();
      verify(eventHandlers.onSelect('cantaloupe')).called(1);
      expect(textField.controller.text, equals('Cantaloupe'));
    },
  );

  testWidgets(
    'Typeahead - focusing and blurring multiple times should not crash the app',
    (tester) async {
      final app = App();
      await tester.pumpWidget(app);

      // type 'a' and unfocus
      final textFiledFinder = find.byType(TextField);
      await tester.enterText(textFiledFinder, 'a');
      await tester.pump(duration);
      final textField = tester.widget<TextField>(textFiledFinder);
      textField.focusNode.unfocus();

      // focus on the text field
      await tester.tap(textFiledFinder);
      await tester.enterText(textFiledFinder, 'b');
      await tester.pump(duration);
      expect(textField.controller.text, equals('b'));
    },
  );

  testWidgets(
    'Typeahead - filter suggestions after updating the text field',
    (tester) async {
      eventHandlers = MockTypeaheadEventHandler();
      when(eventHandlers.onChange('Banana')).thenReturn([suggestions[1]]);
      final app = App(
        addOptionHandler: _addOptionHandler,
        onChange: eventHandlers.onChange,
        onSelect: eventHandlers.onSelect,
      );

      // typing Banana will display Banana and 'Add "Banana"' as suggestions
      await tester.pumpWidget(app);
      final textFieldFinder = find.byType(TextField);
      final textField = tester.widget<TextField>(textFieldFinder);
      await tester.enterText(textFieldFinder, 'Banana');
      await tester.pump(duration);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(textField.controller.text, equals('Banana'));
    },
  );
}

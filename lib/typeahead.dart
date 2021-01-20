library typeahead;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Suggestion<T> {
  final String label;
  final T value;

  Suggestion({
    @required this.label,
    @required this.value,
  });
}

class Typeahead<T> extends StatefulWidget {
  final Future<Suggestion> Function(String) addOptionHandler;
  final Color color;
  final int delay;
  final String hintText;
  final Function onChange;
  final Function onSelect;
  final List<Suggestion<T>> suggestions;
  final TextAlign textAlign;

  Typeahead({
    Key key,
    this.addOptionHandler,
    this.color = Colors.black,
    this.delay = 0,
    this.hintText,
    this.onChange,
    @required this.onSelect,
    @required this.suggestions,
    this.textAlign = TextAlign.left,
  }) : super(key: key);

  @override
  _TypeaheadState createState() => _TypeaheadState();
}

class _TypeaheadState extends State<Typeahead> {
  final _controller = TextEditingController();
  final _filteredSuggestions = StreamController<List<Suggestion>>.broadcast();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _scrollController = ScrollController();
  Timer _debounce;
  bool _hasSelected = false;
  OverlayEntry _overlayEntry;
  StreamController<String> _query;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusNodeHandler);

    if (hasOnChangeOrAddOptionHandler()) {
      _query = StreamController<String>.broadcast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChangedHander,
        textAlign: widget.textAlign,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: TextStyle(color: widget.color),
        ),
        style: GoogleFonts.rubik(
          color: widget.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _focusNodeHandler() {
    if (_focusNode.hasFocus) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry);
    } else {
      _overlayEntry.remove();
    }
  }

  bool hasOnChangeOrAddOptionHandler() {
    return widget.onChange != null || widget.addOptionHandler != null;
  }

  void _onChangedHander(String value) {
    _debounce?.cancel();

    if (hasOnChangeOrAddOptionHandler()) {
      _query.sink.add(value);
    }

    if (widget.onChange == null) {
      _debounce = Timer(Duration(milliseconds: widget.delay), () {
        final suggestions = widget.suggestions
            .where((s) => s.label.contains(_controller.text))
            .toList();

        _filteredSuggestions.sink.add(suggestions);
        _hasSelected = false;
        _debounce.cancel();
      });
    } else {
      _debounce = Timer(Duration(milliseconds: widget.delay), () {
        _filteredSuggestions.sink.add(widget.onChange(value));
        _hasSelected = false;
        _debounce.cancel();
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject();
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4,
            child: StreamBuilder(
              stream: _filteredSuggestions.stream,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<Suggestion>> snapshot,
              ) {
                if (_controller.text.isNotEmpty) {
                  return _createDropdown(snapshot.data ?? []);
                }

                return Container();
              },
            ),
          ),
        ),
      ),
    );
  }

  ConstrainedBox _createDropdown(List<Suggestion> suggestions) {
    final hasAddOptionHandler = widget.addOptionHandler != null;
    var itemCount = suggestions.length;

    if (hasAddOptionHandler && !_hasSelected) {
      itemCount += 1;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        padding: EdgeInsets.all(0),
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          var isLastElement = index + 1 == itemCount;

          if (hasAddOptionHandler && isLastElement && !_hasSelected) {
            return StreamBuilder(
              stream: _query.stream,
              builder: (context, AsyncSnapshot<String> snapshot) {
                return ListTile(
                  onTap: _addOptionHandler,
                  title: Text(
                    'Add "${snapshot.data}"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      color: Color.fromRGBO(42, 193, 126, 1),
                      fontSize: 14,
                      letterSpacing: 0.25,
                    ),
                  ),
                );
              },
            );
          }

          return ListTile(
            title: Text(
              suggestions[index].label,
              style: GoogleFonts.rubik(
                color: Color.fromRGBO(51, 51, 51, 0.8),
                fontSize: 14,
                letterSpacing: 0.25,
              ),
            ),
            onTap: () {
              _focusNode.unfocus();
              _setSelected(suggestions[index]);
            },
          );
        },
      ),
    );
  }

  void _addOptionHandler() async {
    final s = await widget.addOptionHandler(_controller.text);
    _setSelected(s);
  }

  void _setSelected(Suggestion suggestion) {
    _controller.text = suggestion.label;
    _hasSelected = true;
    widget.onSelect(suggestion.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    _filteredSuggestions.close();
    _focusNode.dispose();
    _scrollController.dispose();

    if (hasOnChangeOrAddOptionHandler()) {
      _query.close();
    }

    super.dispose();
  }
}

part of flutter_parsed_text;

List<InlineSpan> _parsedSpans(
    {required String text,
    required List<MatchText> parsers,
    TextStyle? style,
    RegexOptions regexOptions = const RegexOptions()}) {
  String newString = text;

  Map<String, MatchText> _mapping = Map<String, MatchText>();

  parsers.forEach((e) {
    if (e.type == ParsedType.EMAIL) {
      _mapping[emailPattern] = e;
    } else if (e.type == ParsedType.PHONE) {
      _mapping[phonePattern] = e;
    } else if (e.type == ParsedType.URL) {
      _mapping[urlPattern] = e;
    } else {
      _mapping[e.pattern!] = e;
    }
  });

  final pattern = '(${_mapping.keys.toList().join('|')})';

  List<InlineSpan> widgets = [];

  newString.splitMapJoin(
    RegExp(
      pattern,
      multiLine: regexOptions.multiLine,
      caseSensitive: regexOptions.caseSensitive,
      dotAll: regexOptions.dotAll,
      unicode: regexOptions.unicode,
    ),
    onMatch: (Match match) {
      final matchText = match[0];

      final mapping = _mapping[matchText!] ??
          _mapping[_mapping.keys.firstWhere((element) {
            final reg = RegExp(
              element,
              multiLine: regexOptions.multiLine,
              caseSensitive: regexOptions.caseSensitive,
              dotAll: regexOptions.dotAll,
              unicode: regexOptions.unicode,
            );
            return reg.hasMatch(matchText);
          }, orElse: () {
            return '';
          })];

      InlineSpan widget;

      if (mapping != null) {
        if (mapping.renderText != null) {
          Map<String, String> result =
              mapping.renderText!(str: matchText, pattern: pattern);

          TapGestureRecognizer? recognizer;

          if (mapping.onTap != null) {
            recognizer = TapGestureRecognizer();
            recognizer.onTap = () {
              final value = result['value'] ?? matchText;
              mapping.onTap?.call(value);
            };
          }

          widget = TextSpan(
            text: "${result['display']}",
            style: mapping.style != null ? mapping.style : style,
            recognizer: recognizer,
          );
        } else if (mapping.renderTextSpan != null) {
          widget = mapping.renderTextSpan!(str: matchText, pattern: pattern);
        } else if (mapping.renderWidget != null) {
          Widget child =
              mapping.renderWidget!(text: matchText, pattern: mapping.pattern!);

          if (mapping.onTap != null) {
            child = GestureDetector(
              onTap: () => mapping.onTap!(matchText),
              child: child,
            );
          }

          widget = WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: child,
          );
        } else {
          TapGestureRecognizer? recognizer;

          if (mapping.onTap != null) {
            recognizer = TapGestureRecognizer();
            recognizer.onTap = () {
              mapping.onTap!(matchText);
            };
          }

          widget = TextSpan(
            text: "$matchText",
            style: mapping.style != null ? mapping.style : style,
            recognizer: recognizer,
          );
        }
      } else {
        widget = TextSpan(
          text: "$matchText",
          style: style,
        );
      }

      widgets.add(widget);

      return '';
    },
    onNonMatch: (String text) {
      widgets.add(TextSpan(
        text: "$text",
        style: style,
      ));

      return '';
    },
  );

  return widgets;
}

class ParsedTextSpan extends TextSpan {
  ParsedTextSpan({
    required String text,
    required List<MatchText> parsers,
    TextStyle? style,
    RegexOptions regexOptions = const RegexOptions(),
  }) : super(
          children: _parsedSpans(
            text: text,
            parsers: parsers,
            style: style,
            regexOptions: regexOptions,
          ),
          style: style,
        );
}

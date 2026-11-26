import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'country_config.dart';
import 'dialect_pack.dart';

/// Drop-in replacement for Flutter's `Text`. Every visible Arabic line goes
/// through the dialect packs at build time. The key is the Egyptian text
/// written in the code, so Egyptian (the default and the fallback) shows the
/// code text unchanged, and any other dialect only needs a pack file.
class Text extends StatelessWidget {
  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  @override
  Widget build(BuildContext context) {
    if (textSpan != null) {
      return m.Text.rich(textSpan!,
          style: style, strutStyle: strutStyle, textAlign: textAlign,
          textDirection: textDirection, locale: locale, softWrap: softWrap,
          overflow: overflow, textScaler: textScaler, maxLines: maxLines,
          semanticsLabel: semanticsLabel, textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor);
    }
    // Depend on the scope so a dialect change rebuilds this text.
    final DialectId d = DialectScope.of(context);
    final String shown = DialectPacks.tr(data!, dialect: d);
    return m.Text(shown,
        style: style, strutStyle: strutStyle, textAlign: textAlign,
        textDirection: textDirection, locale: locale, softWrap: softWrap,
        overflow: overflow, textScaler: textScaler, maxLines: maxLines,
        semanticsLabel: semanticsLabel == null
            ? null
            : DialectPacks.tr(semanticsLabel!, dialect: d),
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor);
  }
}

/// Put once above the app. Changing [dialect] rebuilds every [Text].
class DialectScope extends InheritedWidget {
  final DialectId dialect;
  const DialectScope({super.key, required this.dialect, required super.child});

  static DialectId of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<DialectScope>();
    return s?.dialect ?? DialectId.egyptian;
  }

  @override
  bool updateShouldNotify(DialectScope old) => old.dialect != dialect;
}

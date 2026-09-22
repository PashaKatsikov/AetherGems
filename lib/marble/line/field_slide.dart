import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'page_hooks.dart';

/// Keyboard measurements for the court WebView.
///
/// The window stays put when the IME opens, so the keyboard only shows up as
/// a view inset. That inset is turned into a 0..1 share of the visible span
/// and handed to the page, which seats its own focused field. The hardware
/// cutout is read on demand over `gemwell/lift` because the window is laid
/// out edge to edge and Flutter's own padding is stripped for the page.
class FieldSlide {
  static const MethodChannel _channel = MethodChannel('gemwell/lift');

  final ValueNotifier<EdgeInsets> cutout =
      ValueNotifier<EdgeInsets>(EdgeInsets.zero);

  WebViewController? _web;
  bool _gone = false;
  double _insetLogical = 0;
  double _spanPx = -1;
  double _share = 0;

  /// Share of the viewport the keyboard currently covers, 0..1.
  double get share => _share;

  void bind(WebViewController controller) {
    _web = controller;
  }

  /// Re-reads the keyboard inset and pushes it to the page when either the
  /// inset or the span it is measured against has moved.
  void measure(FlutterView view) {
    if (_gone) return;
    final double ratio = view.devicePixelRatio;
    if (ratio <= 0) return;

    final EdgeInsets rim = cutout.value;
    final double span =
        view.physicalSize.height - (rim.top + rim.bottom) * ratio;
    if (span <= 0) return;

    final double inset = view.viewInsets.bottom / ratio;
    final bool insetMoved = (inset - _insetLogical).abs() >= 1;
    final bool spanMoved = (span - _spanPx).abs() >= 1;
    if (!insetMoved && !spanMoved) return;

    _insetLogical = inset;
    _spanPx = span;

    final double next = (inset * ratio / span).clamp(0.0, 1.0);
    if ((next - _share).abs() < 0.0001) return;
    _share = next;
    unawaited(cast());
  }

  /// Re-sends the last measured share, used once a fresh page has settled.
  Future<void> cast() async {
    final WebViewController? web = _web;
    if (web == null || _gone) return;
    await PageHooks.castShare(web, _share);
  }

  Future<void> readCutout(double ratio) async {
    if (_gone || ratio <= 0) return;
    try {
      final Object? raw = await _channel.invokeMethod<Object>('notch');
      if (_gone || raw is! Map) return;

      double edge(Object? value) {
        final double px = (value as num?)?.toDouble() ?? 0;
        return px <= 0 ? 0 : px / ratio;
      }

      final EdgeInsets next = EdgeInsets.fromLTRB(
        edge(raw['left']),
        edge(raw['top']),
        edge(raw['right']),
        edge(raw['bottom']),
      );
      if (next != cutout.value) cutout.value = next;
    } catch (_) {}
  }

  void dispose() {
    _gone = true;
    _web = null;
    cutout.dispose();
  }
}

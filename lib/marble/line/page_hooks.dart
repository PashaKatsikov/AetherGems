import 'package:webview_flutter/webview_flutter.dart';

import '../tablet/sealed_runes.dart';

// Everything the court page needs injected after a load settles. The seat
// script is the one that matters for typing: the window never moves for the
// keyboard, so the page lifts its own focused field once Dart hands it the
// occupancy share.
class PageHooks {
  PageHooks._();

  static Future<void> installAll(WebViewController controller) async {
    for (final String body in _bodies()) {
      if (body.isEmpty) continue;
      try {
        await controller.runJavaScript(body);
      } catch (_) {}
    }
  }

  /// Hands the page the share of the viewport the keyboard is eating, 0..1.
  static Future<void> castShare(
    WebViewController controller,
    double share,
  ) async {
    try {
      await controller.runJavaScript(
        'window.__k3Share&&window.__k3Share(${share.toStringAsFixed(5)});',
      );
    } catch (_) {}
  }

  static List<String> _bodies() => <String>[
        openJsInsetScript(),
        openJsSeatScript(),
        openJsPlayScript(),
      ];
}

import 'dart:io';

import '../tablet/sealed_runes.dart';
import 'handset_read.dart';

// Assembles a device User-Agent shared by HttpLane and the court WebView.
// Browser fragments come from sealed runes. The fallback below is only
// reached when those fragments are empty.

class HandsetMark {
  HandsetMark._();

  static String _ua = '';

  static String get userAgent {
    if (_ua.isEmpty) return _fallback();
    return _ua;
  }

  static Future<void> prime() async {
    try {
      if (!Platform.isAndroid) return;
      final AndroidBuildFields? info = await HandsetRead.readAndroid();
      if (info == null) return;
      _ua = _assembleAndroid(
        release: info.release,
        brand: _titleCase(info.brand),
        model: info.model,
        buildTag: info.display.isNotEmpty ? info.display : 'AP2A.240805.005',
      );
    } catch (_) {
      _ua = _fallback();
    }
  }

  static String _assembleAndroid({
    required String release,
    required String brand,
    required String model,
    required String buildTag,
  }) {
    final String chrome = _or(openChromeVersion(), '148.0.7730.86');
    final String webkit = _or(openWebkitVersion(), '537.36');
    final String product = _or(openUaProduct(), _seedProduct);
    final String platformOpen = _or(openUaLinuxOpen(), _seedLinuxOpen);
    final String buildLabel = _or(openUaBuildLabel(), _seedBuildLabel);
    final String platformClose = _or(openUaBuildClose(), _seedBuildClose);
    final String engineLabel = _or(openUaEngineLabel(), _seedEngineLabel);
    final String engineTail = _or(openUaEngineTail(), _seedEngineTail);
    final String chromeLabel = _or(openUaChromeLabel(), _seedChromeLabel);
    final String safariLabel = _or(openUaMobileSafari(), _seedSafariLabel);

    return '$product $platformOpen $release; $brand $model'
        '$buildLabel$buildTag$platformClose'
        '$engineLabel$webkit$engineTail'
        '$chromeLabel$chrome'
        '$safariLabel$webkit';
  }

  static String _fallback() => _assembleAndroid(
        release: '14',
        brand: 'Samsung',
        model: 'SM-S921B',
        buildTag: 'AP2A.240805.005',
      );

  static String _or(String encoded, String fallback) =>
      encoded.isNotEmpty ? encoded : fallback;

  static String _titleCase(String v) {
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1);
  }

  static String _join(List<int> a, List<int> b) =>
      String.fromCharCodes(a) + String.fromCharCodes(b);

  static String get _seedProduct => _join(
        const <int>[77, 111, 122, 105],
        const <int>[108, 108, 97, 47, 53, 46, 48],
      );

  static String get _seedLinuxOpen => _join(
        const <int>[40, 76, 105, 110, 117, 120, 59, 32],
        const <int>[65, 110, 100, 114, 111, 105, 100],
      );

  static String get _seedBuildLabel =>
      String.fromCharCodes(const <int>[32, 66, 117, 105, 108, 100, 47]);

  static String get _seedBuildClose => String.fromCharCode(41);

  static String get _seedEngineLabel => _join(
        const <int>[32, 65, 112, 112, 108, 101],
        const <int>[87, 101, 98, 75, 105, 116, 47],
      );

  static String get _seedEngineTail => _join(
        const <int>[32, 40, 75, 72, 84, 77, 76, 44, 32],
        const <int>[108, 105, 107, 101, 32, 71, 101, 99, 107, 111, 41],
      );

  static String get _seedChromeLabel =>
      String.fromCharCodes(const <int>[32, 67, 104, 114, 111, 109, 101, 47]);

  static String get _seedSafariLabel => _join(
        const <int>[32, 77, 111, 98, 105, 108, 101, 32],
        const <int>[83, 97, 102, 97, 114, 105, 47],
      );
}

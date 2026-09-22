import 'dart:io';

import 'package:flutter/services.dart';

class HandsetRead {
  HandsetRead._();

  static const MethodChannel _channel = MethodChannel('gemwell/stamp');

  static Future<AndroidBuildFields?> readAndroid() async {
    if (!Platform.isAndroid) return null;
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMapMethod<Object?, Object?>('stamp');
      if (raw == null) return null;
      return AndroidBuildFields(
        release: (raw['os'] as String?) ?? '',
        brand: (raw['maker'] as String?) ?? '',
        model: (raw['unit'] as String?) ?? '',
        display: (raw['label'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

class AndroidBuildFields {
  const AndroidBuildFields({
    required this.release,
    required this.brand,
    required this.model,
    required this.display,
  });

  final String release;
  final String brand;
  final String model;
  final String display;
}

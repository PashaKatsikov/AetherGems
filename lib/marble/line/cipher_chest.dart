import 'package:flutter/services.dart';

// Encrypted key/value bridge. Native side is EncryptedSharedPreferences
// on gemwell/chest.

class CipherChest {
  const CipherChest();

  static const MethodChannel _channel = MethodChannel('gemwell/chest');

  Future<String?> read(String key) async {
    try {
      return await _channel.invokeMethod<String>('take', <String, dynamic>{
        'key': key,
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _channel.invokeMethod<void>('keep', <String, dynamic>{
        'key': key,
        'value': value,
      });
    } catch (_) {}
  }

  Future<void> delete(String key) async {
    try {
      await _channel.invokeMethod<void>('drop', <String, dynamic>{'key': key});
    } catch (_) {}
  }
}

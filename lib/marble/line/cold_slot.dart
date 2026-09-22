import 'slate_box.dart';

abstract final class ColdSlot {
  static Future<String?> consume(SlateBox slate) async {
    final String? parked = await slate.consumePendingUrl();
    if (parked == null) return null;
    final String trimmed = parked.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}

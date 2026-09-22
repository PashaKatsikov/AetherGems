import 'package:shared_preferences/shared_preferences.dart';

import '../omen/arrival.dart';
import '../tablet/court_spec.dart';
import 'cipher_chest.dart';

const String _keyPrefix = 'k3r_';

class SlateBox {
  SlateBox({CipherChest? secure}) : _secure = secure ?? const CipherChest();

  static const String _kRoute = '${_keyPrefix}mark';
  static const String _kCachedUrl = '${_keyPrefix}href';
  static const String _kCachedExpiry = '${_keyPrefix}href_end';
  static const String _kPermSnoozeUntil = '${_keyPrefix}ask_until';
  static const String _kPermGranted = '${_keyPrefix}ask_yes';
  static const String _kPermOsDenied = '${_keyPrefix}ask_os';
  static const String _kInviteConsumed = '${_keyPrefix}asked';
  static const String _kPendingUrl = '${_keyPrefix}tap';

  late final SharedPreferences _prefs;
  final CipherChest _secure;

  Future<void> prime() async {
    _prefs = await SharedPreferences.getInstance();
  }

  RouteMark get route => RouteMark.parse(_prefs.getString(_kRoute));

  Future<void> saveRoute(RouteMark value) =>
      _prefs.setString(_kRoute, value.wireValue);

  Future<String?> cachedDestination() => _secure.read(_kCachedUrl);

  Future<void> cacheDestination(String url, int? expiresUnix) async {
    await _secure.write(_kCachedUrl, url);
    final int until = expiresUnix ??
        _nowSeconds() + CourtSpec.cachedUrlLifetimeSeconds;
    await _prefs.setInt(_kCachedExpiry, until);
  }

  bool get cachedDestinationExpired {
    final int? until = _prefs.getInt(_kCachedExpiry);
    if (until == null) return true;
    return _nowSeconds() >= until;
  }

  bool get permissionGranted => _prefs.getBool(_kPermGranted) ?? false;

  Future<void> markPermissionGranted(bool value) =>
      _prefs.setBool(_kPermGranted, value);

  bool get permissionBlockedByOs => _prefs.getBool(_kPermOsDenied) ?? false;

  Future<void> markPermissionBlockedByOs() =>
      _prefs.setBool(_kPermOsDenied, true);

  bool get permissionInviteConsumed => _prefs.getBool(_kInviteConsumed) ?? false;

  Future<void> markPermissionInviteConsumed() =>
      _prefs.setBool(_kInviteConsumed, true);

  Future<void> writePermissionSnoozeUntil(int unixSeconds) =>
      _prefs.setInt(_kPermSnoozeUntil, unixSeconds);

  bool get shouldInvitePermission {
    if (permissionInviteConsumed) return false;
    final int? until = _prefs.getInt(_kPermSnoozeUntil);
    if (until == null) return true;
    return _nowSeconds() >= until;
  }

  Future<void> stashPendingUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _secure.delete(_kPendingUrl);
    } else {
      await _secure.write(_kPendingUrl, url);
    }
  }

  Future<String?> consumePendingUrl() async {
    final String? url = await _secure.read(_kPendingUrl);
    if (url != null) await _secure.delete(_kPendingUrl);
    return url;
  }

  static int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

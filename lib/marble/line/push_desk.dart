import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'http_lane.dart';
import 'slate_box.dart';

const String kHeraldChannelId = 'gem_herald_v2';
const String kHeraldChannelName = 'Court Herald';
const String _smallIcon = '@drawable/ic_notification';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {}

class PushDesk {
  PushDesk(this._slate);

  final SlateBox _slate;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  String? _token;
  bool _ready = false;

  void Function(String url)? onIncomingUrl;
  void Function(String token)? onTokenChanged;

  String? get token => _token;

  Future<void> boot() async {
    if (_ready) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_bgHandler);
      await _setupLocal();

      final RemoteMessage? initial = await _messaging!.getInitialMessage();
      if (initial != null) {
        await _onColdTap(initial);
      } else {
        await _slate.stashPendingUrl(null);
      }

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onWarmTap);
      _messaging!.onTokenRefresh.listen((String t) {
        _token = t;
        onTokenChanged?.call(t);
      });

      try {
        _token = await _messaging!.getToken().timeout(const Duration(seconds: 6));
      } catch (_) {
        _token = null;
      }
      _ready = true;
    } catch (_) {}
  }

  Future<void> _setupLocal() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings(_smallIcon);
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        final String? payload = r.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final Map<String, dynamic> data =
              jsonDecode(payload) as Map<String, dynamic>;
          final String? url = data['url'] as String?;
          if (url != null && url.isNotEmpty) onIncomingUrl?.call(url);
        } catch (_) {}
      },
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _local.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          kHeraldChannelId,
          kHeraldChannelName,
          description: 'Olympus offers and court bonuses',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<bool> askPermission() async {
    FirebaseMessaging? messaging = _messaging;
    if (messaging == null) {
      try {
        if (Firebase.apps.isEmpty) await Firebase.initializeApp();
        messaging = FirebaseMessaging.instance;
        _messaging = messaging;
      } catch (_) {}
    }
    if (messaging == null) return false;

    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final AuthorizationStatus status = settings.authorizationStatus;
    final bool granted = status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
    await _slate.markPermissionGranted(granted);
    if (status == AuthorizationStatus.denied) {
      await _slate.markPermissionBlockedByOs();
    }
    if (granted) {
      try {
        final String? fresh =
            await messaging.getToken().timeout(const Duration(seconds: 6));
        if (fresh != null && fresh.isNotEmpty) {
          _token = fresh;
          onTokenChanged?.call(fresh);
        }
      } catch (_) {}
    }
    return granted;
  }

  void _onForeground(RemoteMessage message) async {
    final RemoteNotification? n = message.notification;
    if (n == null || !Platform.isAndroid) return;

    AndroidNotificationDetails? details;
    final String? imageUrl = n.android?.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final Uint8List? bytes = await _fetchImage(imageUrl);
      if (bytes != null) {
        details = AndroidNotificationDetails(
          kHeraldChannelId,
          kHeraldChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: _smallIcon,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon: const DrawableResourceAndroidBitmap(_smallIcon),
          ),
        );
      }
    }

    details ??= const AndroidNotificationDetails(
      kHeraldChannelId,
      kHeraldChannelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: _smallIcon,
    );

    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(android: details),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  Future<void> _onColdTap(RemoteMessage message) async {
    final String? url = message.data['url'] as String?;
    await _slate.stashPendingUrl(
      url != null && url.isNotEmpty ? url : null,
    );
  }

  void _onWarmTap(RemoteMessage message) {
    final String? url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) onIncomingUrl?.call(url);
  }

  Future<Uint8List?> _fetchImage(String url) async {
    try {
      final dynamic res =
          await httpLane.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return res.bodyBytes as Uint8List;
    } catch (_) {}
    return null;
  }
}

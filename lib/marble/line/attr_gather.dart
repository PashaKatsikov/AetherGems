import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

import '../tablet/court_spec.dart';

class AttrGather {
  AttrGather();

  AppsflyerSdk? _sdk;

  Map<String, dynamic>? _installPayload;
  Map<String, dynamic>? _deepLinkPayload;
  Map<String, dynamic>? _appOpenPayload;

  final Completer<Map<String, dynamic>> _installReady =
      Completer<Map<String, dynamic>>();
  final Completer<void> _deepLinkReady = Completer<void>();

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final String devKey = CourtSpec.attributionKey;
    if (devKey.isEmpty) {
      _resolveInstall(<String, dynamic>{});
      _resolveDeepLink();
      return;
    }

    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: CourtSpec.storeNumericId,
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 14,
    );

    final AppsflyerSdk sdk = AppsflyerSdk(options);
    _sdk = sdk;

    sdk.onInstallConversionData((dynamic raw) {
      final Map<String, dynamic> payload = _unpackMap(raw);
      _installPayload = payload;
      _resolveInstall(payload);
    });

    sdk.onAppOpenAttribution((dynamic raw) {
      _appOpenPayload = _unpackMap(raw);
    });

    sdk.onDeepLinking((DeepLinkResult result) {
      final Map<String, dynamic>? click = result.deepLink?.clickEvent;
      if (click != null) {
        _deepLinkPayload = Map<String, dynamic>.from(click);
      }
      _resolveDeepLink();
    });

    try {
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (_) {
      _resolveInstall(<String, dynamic>{});
      _resolveDeepLink();
    }
  }

  Future<void> awaitSignals({int? installSeconds}) async {
    final int seconds = installSeconds ?? CourtSpec.firstInstallAwaitSeconds;
    final int deepLinkSeconds = seconds < CourtSpec.deepLinkAwaitSeconds
        ? seconds
        : CourtSpec.deepLinkAwaitSeconds;
    await Future.wait<void>(<Future<void>>[
      _installReady.future.timeout(
        Duration(seconds: seconds),
        onTimeout: () => <String, dynamic>{},
      ),
      _deepLinkReady.future.timeout(
        Duration(seconds: deepLinkSeconds),
        onTimeout: () {},
      ),
    ]);
  }

  Future<String?> deviceId() async {
    if (_sdk == null) return null;
    try {
      return await _sdk!.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> compose({
    required String locale,
    String? pushToken,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};

    if (_installPayload != null) body.addAll(_installPayload!);
    _deepLinkPayload?.forEach((String k, dynamic v) => body.putIfAbsent(k, () => v));
    _appOpenPayload?.forEach((String k, dynamic v) => body.putIfAbsent(k, () => v));

    body['af_id'] = await deviceId() ?? '';
    body['bundle_id'] = CourtSpec.applicationId;
    body['os'] = Platform.isAndroid ? 'Android' : 'iOS';
    body['store_id'] = CourtSpec.storeId;
    body['locale'] = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
      final String project = CourtSpec.messagingProjectId;
      if (project.isNotEmpty) {
        body['firebase_project_id'] = project;
      }
    }

    assert(() {
      // ignore: avoid_print
      print('[MARBLE.GATHER] compose ${jsonEncode(body)}');
      return true;
    }());
    return body;
  }

  void _resolveInstall(Map<String, dynamic> data) {
    if (!_installReady.isCompleted) _installReady.complete(data);
  }

  void _resolveDeepLink() {
    if (!_deepLinkReady.isCompleted) _deepLinkReady.complete();
  }

  static Map<String, dynamic> _unpackMap(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final dynamic inner = raw['payload'] ?? raw['data'] ?? raw;
    if (inner is Map) {
      return inner.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v),
      );
    }
    return <String, dynamic>{};
  }
}

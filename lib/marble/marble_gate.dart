import 'dart:async';
import 'dart:io';

import 'line/attr_gather.dart';
import 'line/cold_slot.dart';
import 'line/push_desk.dart';
import 'line/reach_tap.dart';
import 'line/ruling_post.dart';
import 'line/slate_box.dart';
import 'omen/arrival.dart';
import 'tablet/court_spec.dart';

class MarbleGate {
  MarbleGate({
    required this.slate,
    required this.reach,
    required this.gather,
    required this.ruling,
    required this.desk,
  });

  final SlateBox slate;
  final ReachTap reach;
  final AttrGather gather;
  final RulingPost ruling;
  final PushDesk desk;

  Future<Arrival>? _inFlight;

  Future<Arrival> decide({void Function(double)? onProgress}) {
    return _inFlight ??= _decide(onProgress ?? (_) {})
        .whenComplete(() => _inFlight = null);
  }

  Future<Arrival> _decide(void Function(double) onProgress) async {
    if (!CourtSpec.credentialsReady) {
      onProgress(0.12);
      return const PlayArrival();
    }

    desk.onTokenChanged = _refreshOnTokenChange;

    try {
      await desk.boot();
    } catch (_) {}

    final String? coldTapUrl = await ColdSlot.consume(slate);
    if (coldTapUrl != null && coldTapUrl.isNotEmpty) {
      await slate.saveRoute(RouteMark.court);
      unawaited(_fireAndForget());
      onProgress(1);
      return PortalArrival(coldTapUrl, coldTap: true);
    }

    onProgress(0.18);
    return switch (slate.route) {
      RouteMark.fresh => _decideFirstLaunch(onProgress),
      RouteMark.court => _decideReturningCourt(onProgress),
      RouteMark.arena => _decideReturningArena(onProgress),
    };
  }

  Future<Arrival> _decideFirstLaunch(void Function(double) onProgress) async {
    if (!await reach.hasAdapter()) {
      return const QuietArrival(returnsToArena: false);
    }
    onProgress(0.34);
    if (!await reach.canDialOut()) {
      return const QuietArrival(returnsToArena: false);
    }
    onProgress(0.55);
    await gather.start();
    await gather.awaitSignals(installSeconds: CourtSpec.firstInstallAwaitSeconds);
    onProgress(0.8);
    final Ruling answer = await _requestRuling();
    onProgress(1);
    if (answer.hasDestination) {
      await slate.saveRoute(RouteMark.court);
      return PortalArrival(answer.url!);
    }
    await slate.saveRoute(RouteMark.arena);
    return const PlayArrival();
  }

  Future<Arrival> _decideReturningCourt(void Function(double) onProgress) async {
    if (!await reach.hasAdapter()) {
      return const QuietArrival(returnsToArena: false);
    }
    final String? pending = await slate.consumePendingUrl();
    if (pending != null && pending.isNotEmpty) {
      onProgress(1);
      return PortalArrival(pending);
    }
    final String? cached = await slate.cachedDestination();
    if (cached != null && !slate.cachedDestinationExpired) {
      onProgress(1);
      return PortalArrival(cached);
    }

    await gather.start();
    if (!await reach.canDialOut()) {
      if (cached != null) return PortalArrival(cached);
      return const QuietArrival(returnsToArena: false);
    }
    onProgress(0.62);
    await gather.awaitSignals(
      installSeconds: CourtSpec.returningInstallAwaitSeconds,
    );
    final Ruling answer = await _requestRuling();
    onProgress(1);
    if (answer.hasDestination) return PortalArrival(answer.url!);
    if (cached != null) return PortalArrival(cached);
    return const QuietArrival(returnsToArena: false);
  }

  Future<Arrival> _decideReturningArena(void Function(double) onProgress) async {
    if (!await reach.hasAdapter()) {
      onProgress(1);
      return const PlayArrival();
    }
    await gather.start();
    if (!await reach.canDialOut()) {
      onProgress(1);
      return const PlayArrival();
    }
    onProgress(0.5);
    await gather.awaitSignals(
      installSeconds: CourtSpec.returningInstallAwaitSeconds,
    );
    final Ruling answer = await _requestRuling();
    onProgress(1);
    if (!answer.hasDestination) return const PlayArrival();
    await slate.saveRoute(RouteMark.court);
    return PortalArrival(answer.url!);
  }

  Future<Ruling> _requestRuling({String? token}) async {
    final Map<String, dynamic> body = await gather.compose(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: token ?? desk.token,
    );
    return ruling.ask(body);
  }

  Future<void> _fireAndForget() async {
    try {
      await gather.start();
      await gather.awaitSignals(
        installSeconds: CourtSpec.returningInstallAwaitSeconds,
      );
      await _requestRuling();
    } catch (_) {}
  }

  Future<void> _refreshOnTokenChange(String token) async {
    try {
      await _requestRuling(token: token);
    } catch (_) {}
  }
}

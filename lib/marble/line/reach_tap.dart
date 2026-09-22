import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../tablet/court_spec.dart';

const List<String> _probeHosts = <String>[
  'www.bing.com',
  'fastly.net',
];

const Set<ConnectivityResult> _liveAdapters = <ConnectivityResult>{
  ConnectivityResult.wifi,
  ConnectivityResult.mobile,
  ConnectivityResult.ethernet,
  ConnectivityResult.vpn,
  ConnectivityResult.bluetooth,
  ConnectivityResult.other,
};

class ReachTap {
  ReachTap({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  int _rotor = 0;

  Future<bool> hasAdapter() async {
    try {
      final List<ConnectivityResult> states =
          await _connectivity.checkConnectivity();
      return states.any(_liveAdapters.contains);
    } catch (_) {
      return false;
    }
  }

  Future<bool> canDialOut() async {
    if (!await hasAdapter()) return false;
    final Duration timeout =
        Duration(seconds: CourtSpec.reachProbeTimeoutSeconds);
    for (int i = 0; i < _probeHosts.length; i++) {
      final String host = _probeHosts[(_rotor + i) % _probeHosts.length];
      try {
        final List<InternetAddress> answer =
            await InternetAddress.lookup(host).timeout(timeout);
        if (answer.any((InternetAddress a) => a.rawAddress.isNotEmpty)) {
          _rotor = (_rotor + 1) % _probeHosts.length;
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Stream<List<ConnectivityResult>> get statusStream =>
      _connectivity.onConnectivityChanged;
}

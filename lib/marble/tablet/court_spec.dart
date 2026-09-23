import 'sealed_runes.dart';

// Court spec — timings and identity for the Aether Gems boot fork.
// Endpoint, attribution key and messaging project resolve through
// sealed_runes.dart so they are not plaintext string literals.

abstract final class CourtSpec {
  static const String applicationId = 'com.crystalpeak.aethergems';
  static const String marketId = 'com.crystalpeak.aethergems';
  static const String displayName = 'Aether Gems';

  /// Numeric store id. Empty on this Android build.
  static const String storeNumericId = '';

  /// Skip on the invite plate hides it for just under three days
  /// (3 days minus 3 minutes 31 seconds), then it returns on a fresh launch.
  static const int permissionSnoozeSeconds = 3 * 24 * 60 * 60 - 211;

  static const int organicRescueDelay = 13;
  static const int verdictTimeoutSeconds = 20;
  static const int firstInstallAwaitSeconds = 35;
  static const int returningInstallAwaitSeconds = 11;
  static const int deepLinkAwaitSeconds = 12;
  static const int reachProbeTimeoutSeconds = 11;
  static const int reachDropDebounceMs = 860;
  static const int redirectLoopRetries = 6;
  static const int cachedUrlLifetimeSeconds = 10 * 24 * 60 * 60;

  static String get endpointUrl => openEndpointUrl();
  static String get attributionKey => openAttributionKey();
  static String get messagingProjectId => openMessagingProject();
  static String get relaySecret => openRelaySecret();

  static String get storeId {
    if (storeNumericId.isNotEmpty) return 'id$storeNumericId';
    return marketId;
  }

  /// Stays shut until the endpoint, AppsFlyer key, Firebase project
  /// number and relay secret are all sealed.
  static bool get credentialsReady =>
      endpointUrl.isNotEmpty &&
      attributionKey.isNotEmpty &&
      messagingProjectId.isNotEmpty &&
      relaySecret.isNotEmpty;
}

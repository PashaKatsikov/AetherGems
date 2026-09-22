// Boot outcomes. MarbleGate is the only producer; BootPage is the
// only switch.

enum RouteMark {
  fresh('fresh'),
  court('court'),
  arena('arena');

  const RouteMark(this.wireValue);

  final String wireValue;

  bool get settled => this != RouteMark.fresh;

  static RouteMark parse(String? raw) {
    switch (raw) {
      case 'court':
        return RouteMark.court;
      case 'arena':
        return RouteMark.arena;
      default:
        return RouteMark.fresh;
    }
  }
}

sealed class Arrival {
  const Arrival();

  bool get opensCourt => false;
}

final class PlayArrival extends Arrival {
  const PlayArrival();
}

final class PortalArrival extends Arrival {
  const PortalArrival(this.url, {this.coldTap = false});

  final String url;
  final bool coldTap;

  @override
  bool get opensCourt => true;
}

final class QuietArrival extends Arrival {
  const QuietArrival({required this.returnsToArena});

  final bool returnsToArena;
}

/// Server body stays `{ok, url, expires, message}`.
class Ruling {
  const Ruling({
    required this.approved,
    this.url,
    this.expiresAt,
    this.note,
  });

  factory Ruling.fromJson(Map<String, dynamic> json) {
    return Ruling(
      approved: json['ok'] == true,
      url: _asText(json['url']),
      expiresAt: _asEpoch(json['expires']),
      note: json['message']?.toString(),
    );
  }

  factory Ruling.rejected(String note) => Ruling(approved: false, note: note);

  final bool approved;
  final String? url;
  final int? expiresAt;
  final String? note;

  bool get hasDestination {
    final String? dest = url;
    return approved && dest != null && dest.isNotEmpty;
  }

  static String? _asText(Object? raw) => raw is String ? raw : null;

  static int? _asEpoch(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}

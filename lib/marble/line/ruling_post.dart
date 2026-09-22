import 'dart:convert';

import '../omen/arrival.dart';
import '../tablet/court_spec.dart';
import 'court_wrap.dart';
import 'http_lane.dart';
import 'slate_box.dart';

class RulingPost {
  RulingPost(this._slate);

  final SlateBox _slate;

  Future<Ruling> ask(Map<String, dynamic> body) async {
    final String endpoint = CourtSpec.endpointUrl;
    final String secret = CourtSpec.relaySecret;
    if (endpoint.isEmpty || secret.isEmpty) {
      return Ruling.rejected('endpoint_missing');
    }

    try {
      final Map<String, dynamic> envelope = CourtWrap.seal(body, secret);
      final dynamic response = await httpLane
          .post(
            Uri.parse(endpoint),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(envelope),
          )
          .timeout(Duration(seconds: CourtSpec.verdictTimeoutSeconds));

      if (response.statusCode != 200) {
        return Ruling.rejected('http_${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) return Ruling.rejected('malformed');
      final Ruling ruling = Ruling.fromJson(Map<String, dynamic>.from(decoded));
      if (ruling.hasDestination) {
        await _slate.cacheDestination(ruling.url!, ruling.expiresAt);
      }
      return ruling;
    } catch (e) {
      return Ruling.rejected('network:$e');
    }
  }
}

import 'package:http/http.dart' as http;

import 'handset_mark.dart';

class HttpLane extends http.BaseClient {
  HttpLane();

  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['User-Agent'] = HandsetMark.userAgent;
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

final HttpLane httpLane = HttpLane();

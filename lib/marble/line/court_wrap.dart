import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

// Opaque POST body for /edge/sync. Schema 13, keys a / m / w / e.
//
//   raw       = utf8(compact json)
//   keystream = sha256(secret + nonce + counter_be32), counter 0, 1, 2…
//   enc       = raw XOR keystream
//   w         = base64url(enc) without '='
//   e         = HMAC_SHA256(secret, nonce + enc).hex()[:16]
//   m         = 16 random bytes, hex

abstract final class CourtWrap {
  static const int schemaRev = 13;

  static final Random _rng = Random.secure();

  static Map<String, dynamic> seal(Map<String, dynamic> body, String secret) {
    final Uint8List secretBytes = Uint8List.fromList(utf8.encode(secret));
    final Uint8List raw = Uint8List.fromList(utf8.encode(jsonEncode(body)));
    final Uint8List nonce = _nonce(16);
    final Uint8List stream = _keystream(secretBytes, nonce, raw.length);

    final Uint8List enc = Uint8List(raw.length);
    for (int i = 0; i < raw.length; i++) {
      enc[i] = raw[i] ^ stream[i];
    }

    return <String, dynamic>{
      'a': schemaRev,
      'm': _hex(nonce),
      'w': base64Url.encode(enc).replaceAll('=', ''),
      'e': _tag(secretBytes, nonce, enc),
    };
  }

  static Uint8List _keystream(Uint8List secret, Uint8List nonce, int length) {
    final BytesBuilder out = BytesBuilder(copy: false);
    int counter = 0;
    while (out.length < length) {
      final Uint8List block = Uint8List(secret.length + nonce.length + 4);
      block.setRange(0, secret.length, secret);
      block.setRange(secret.length, secret.length + nonce.length, nonce);
      final ByteData ctr = ByteData(4)..setUint32(0, counter, Endian.big);
      block.setRange(
        secret.length + nonce.length,
        block.length,
        ctr.buffer.asUint8List(),
      );
      out.add(sha256.convert(block).bytes);
      counter++;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, length));
  }

  static String _tag(Uint8List secret, Uint8List nonce, Uint8List enc) {
    final Uint8List msg = Uint8List(nonce.length + enc.length);
    msg.setRange(0, nonce.length, nonce);
    msg.setRange(nonce.length, msg.length, enc);
    final Digest digest = Hmac(sha256, secret).convert(msg);
    return _hex(Uint8List.fromList(digest.bytes)).substring(0, 16);
  }

  static Uint8List _nonce(int n) {
    final Uint8List b = Uint8List(n);
    for (int i = 0; i < n; i++) {
      b[i] = _rng.nextInt(256);
    }
    return b;
  }

  static String _hex(Uint8List bytes) {
    final StringBuffer sb = StringBuffer();
    for (final int b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}

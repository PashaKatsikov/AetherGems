import 'dart:convert';
import 'dart:typed_data';

// Marble fold — 16-byte salt, FNV mix, then an xorshift avalanche.
// Twin encoder: tool/rune_seal.dart. Keep the constants identical.

const List<int> _salt = <int>[
  0x3A, 0xC1, 0x07, 0xE4, 0x59, 0x8D, 0x22, 0xF6,
  0x6B, 0x14, 0xA8, 0xD0, 0x4E, 0x93, 0x71, 0xBC,
];

const int _fnvPrime = 0x01000193;
const int _fnvOffset = 0x6C62272E;
const int _addend = 0x45D9F3B;

int _mix(int s) {
  s &= 0xFFFFFFFF;
  s = (s ^ (s << 13)) & 0xFFFFFFFF;
  s = (s ^ (s >> 17)) & 0xFFFFFFFF;
  s = (s ^ (s << 5)) & 0xFFFFFFFF;
  return s;
}

int _seed() {
  int h = _fnvOffset;
  for (final int b in _salt) {
    h = (h ^ b) & 0xFFFFFFFF;
    h = (h * _fnvPrime) & 0xFFFFFFFF;
  }
  return h == 0 ? 0xA5A5A5A5 : h;
}

int _step(int acc, int i) {
  final int saltByte = _salt[i % _salt.length];
  acc = (acc + saltByte + (i * _addend)) & 0xFFFFFFFF;
  return _mix(acc);
}

int _keyByte(int acc, int i) {
  final int lane = (i & 3) * 8;
  return ((acc >> lane) & 0xFF) ^ ((acc >> 3) & 0xFF);
}

String unfoldRunes(List<int> data) {
  if (data.isEmpty) return '';
  final Uint8List out = Uint8List(data.length);
  int acc = _seed();
  for (int i = 0; i < data.length; i++) {
    acc = _step(acc, i);
    out[i] = (data[i] ^ _keyByte(acc, i)) & 0xFF;
  }
  return utf8.decode(out);
}

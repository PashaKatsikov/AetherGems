// ignore_for_file: avoid_print
// rune_seal — encoder twin of lib/marble/fold/rune_fold.dart
//   dart run tool/rune_seal.dart
// Rewrites lib/marble/tablet/sealed_runes.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

List<int> conceal(String plain) {
  if (plain.isEmpty) return const <int>[];
  final List<int> bytes = utf8.encode(plain);
  final List<int> out = List<int>.filled(bytes.length, 0);
  int acc = _seed();
  for (int i = 0; i < bytes.length; i++) {
    acc = _step(acc, i);
    out[i] = (bytes[i] ^ _keyByte(acc, i)) & 0xFF;
  }
  return out;
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

String _fmtArray(List<int> enc) {
  if (enc.isEmpty) return '<int>[]';
  final StringBuffer buf = StringBuffer('<int>[\n');
  for (int i = 0; i < enc.length; i++) {
    if (i % 12 == 0) buf.write('  ');
    buf.write('0x${enc[i].toRadixString(16).toUpperCase().padLeft(2, '0')}');
    buf.write(',');
    if (i % 12 == 11 || i == enc.length - 1) {
      buf.write('\n');
    } else {
      buf.write(' ');
    }
  }
  buf.write(']');
  return buf.toString();
}

void main() {
  // Safe-area neutraliser. Re-applied after SPA navigation and on a slow
  // heartbeat, and skipped while the keyboard is up so it never fights the
  // seat script for the same frame.
  const String jsInset = r'''
(function(){
  if (window.__k3Inset) { return; }
  window.__k3Inset = 1;

  var TAG = 'k3-inset-sheet';
  var RULES = [
    ':root{',
    '--k3-top:0px!important;',
    '--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;',
    '--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;',
    '--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;',
    '--safe-top:0px!important;--safe-bottom:0px!important;',
    '--safe-left:0px!important;--safe-right:0px!important;',
    '}',
    '.k3-pad,.k3-bar,.gem-header,.gameview-mobile-header,.app-header,.js-safe-top',
    '{padding-top:0!important;margin-top:0!important;}'
  ].join('');

  function typing(){
    var vv = window.visualViewport;
    return vv ? (vv.height < window.innerHeight * 0.78) : false;
  }
  function patchMeta(){
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) { return; }
    var content = meta.getAttribute('content') || '';
    if (/viewport-fit\s*=\s*contain/i.test(content)) { return; }
    var trimmed = content.replace(/,?\s*viewport-fit\s*=\s*\w+/ig, '').trim();
    meta.setAttribute('content', trimmed ? (trimmed + ', viewport-fit=contain') : 'viewport-fit=contain');
  }
  function pinSheet(){
    var host = document.head || document.documentElement;
    if (!host) { return; }
    var node = document.getElementById(TAG);
    if (!node){
      node = document.createElement('style');
      node.id = TAG;
      host.appendChild(node);
    }
    if (node.textContent !== RULES) { node.textContent = RULES; }
  }
  function apply(){
    if (typing()) { return; }
    patchMeta();
    pinSheet();
  }
  function applyLater(){
    window.setTimeout(apply, 120);
    window.setTimeout(apply, 520);
  }

  apply();

  var story = window.history;
  ['pushState', 'replaceState'].forEach(function(name){
    var original = story[name];
    if (typeof original !== 'function') { return; }
    story[name] = function(){
      var out = original.apply(this, arguments);
      applyLater();
      return out;
    };
  });
  window.addEventListener('popstate', function(){ window.setTimeout(apply, 120); });
  window.setInterval(apply, 3100);
})();
''';

  // Keyboard seating. The window never moves, so the page lifts its own
  // focused field: a fixed-position host is glided up with a transform,
  // anything else is scrolled into the gap above the keyboard. Occupancy
  // (0..1 of the viewport eaten by the IME) is pushed in from Dart.
  const String jsSeat = r'''
(function(){
  if (window.__k3Seat) { return; }
  window.__k3Seat = 1;

  var occupancy = 0;
  var frame = 0;
  var gen = 0;
  var held = { field: null, host: null, bottom: 0, shift: -1 };
  var CEIL = 0.91;
  var GAP = 6;
  var GLIDE = 'transform 0.2s cubic-bezier(0.22, 0.61, 0.36, 1)';

  function margin(){
    var raw = Math.round(window.innerHeight * 0.018);
    if (raw < 8) { return 8; }
    return raw > 21 ? 21 : raw;
  }
  function collapsed(){
    var vv = window.visualViewport;
    if (!vv || !(vv.height > 0)) { return false; }
    return (window.innerHeight - vv.height) > 1;
  }
  function editable(){
    var node = document.activeElement;
    if (!node || !node.tagName) { return null; }
    if (node.isContentEditable === true) { return node; }
    var tag = ('' + node.tagName).toUpperCase();
    if (tag === 'TEXTAREA' || tag === 'SELECT' || tag === 'INPUT') { return node; }
    return null;
  }
  function pinned(node){
    for (var cur = node ? node.parentElement : null; cur && cur !== document.body; cur = cur.parentElement){
      if (window.getComputedStyle(cur).position === 'fixed') { return cur; }
    }
    return null;
  }
  function keyboardTop(){
    if (occupancy > 0){
      var used = occupancy > CEIL ? CEIL : occupancy;
      return window.innerHeight * (1 - used);
    }
    if (collapsed()){
      var vv = window.visualViewport;
      return vv.offsetTop + vv.height;
    }
    return window.innerHeight;
  }
  function origins(el){
    if (typeof el.__k3Tx0 !== 'string') { el.__k3Tx0 = el.style.transform || ''; }
    if (typeof el.__k3Tr0 !== 'string') { el.__k3Tr0 = el.style.transition || ''; }
  }
  function letGo(instant){
    var host = held.host;
    held = { field: null, host: null, bottom: 0, shift: -1 };
    if (!host) { return; }
    var tx0 = (typeof host.__k3Tx0 === 'string') ? host.__k3Tx0 : '';
    var tr0 = (typeof host.__k3Tr0 === 'string') ? host.__k3Tr0 : '';
    host.style.transform = tx0;
    if (instant){
      host.style.transition = tr0;
      return;
    }
    var mark = ++gen;
    window.setTimeout(function(){
      if (mark === gen && held.host !== host) { host.style.transition = tr0; }
    }, 260);
  }
  function grab(field, host){
    var sameHost = (host === held.host);
    // How much this host is already lifted right now (0 for a fresh host).
    var applied = (sameHost && held.shift > 0) ? held.shift : 0;
    // Release a different previously-held host, gliding it back down.
    if (!sameHost) { letGo(false); }
    origins(host);
    gen++;
    // Natural (unlifted) bottom = current rect plus whatever lift is applied.
    var natural = field.getBoundingClientRect().bottom + applied;
    held = { field: field, host: host, bottom: natural, shift: sameHost ? applied : -1 };
    host.style.transition = host.__k3Tr0 ? (host.__k3Tr0 + ', ' + GLIDE) : GLIDE;
  }
  function place(dy){
    if (dy === held.shift) { return; }
    held.shift = dy;
    var tx0 = (typeof held.host.__k3Tx0 === 'string') ? held.host.__k3Tx0 : '';
    var move = 'translate3d(0px,' + (-dy) + 'px,0px)';
    held.host.style.transform = tx0 ? (tx0 + ' ' + move) : move;
  }
  function reconcile(){
    var el = editable();
    if (!el || occupancy <= 0) { letGo(false); return; }
    var host = pinned(el);
    if (!host){
      if (held.host) { letGo(true); }
      var overlap = el.getBoundingClientRect().bottom + margin() - keyboardTop();
      if (overlap > GAP) { window.scrollBy(0, overlap); }
      return;
    }
    if (held.field !== el || held.host !== host){
      grab(el, host);
    }
    var need = held.bottom + margin() - keyboardTop();
    place(need > GAP ? need : 0);
  }
  function schedule(){
    if (frame) { return; }
    frame = window.requestAnimationFrame(function(){
      frame = 0;
      reconcile();
    });
  }

  window.__k3Share = function(value){
    occupancy = value > 0 ? value : 0;
    if (occupancy <= 0){
      if (frame) { window.cancelAnimationFrame(frame); frame = 0; }
      letGo(false);
      return;
    }
    schedule();
  };

  document.addEventListener('focusin', schedule, true);
  if (window.visualViewport){
    window.visualViewport.addEventListener('resize', schedule);
    window.visualViewport.addEventListener('scroll', schedule);
  }
})();
''';

  const String jsPlay =
      "(function(){if(window.__k3Play)return;window.__k3Play=1;"
      "function tag(node){if(!node||node.nodeName!=='VIDEO')return;"
      "node.setAttribute('playsinline','');node.setAttribute('webkit-playsinline','');"
      "try{node.playsInline=true;}catch(e){}}"
      "function sweep(){var nodes=document.querySelectorAll('video');"
      "for(var i=0;i<nodes.length;i++)tag(nodes[i]);}"
      "sweep();try{var obs=new MutationObserver(function(){sweep();});"
      "obs.observe(document.documentElement,{childList:true,subtree:true});}catch(e){}})();";

  // AppsFlyer dev key and the Firebase project number stay empty until
  // they are supplied. Re-run this tool after filling `_attributionKey`
  // and `_messagingProject`.
  final Map<String, String> values = <String, String>{
    '_endpointUrl': 'https://aethergems.link/edge/sync',
    '_gcdBaseUrl': 'https://gcdsdk.appsflyer.com/install_data/v4.0/',
    '_attributionKey': 'Z4xCKFgFBxttFApwyBN9HE',
    '_messagingProject': '365250523808',
    '_relaySecret': 'izlJGy4QwIs_UNPlzIZPgjuQ4g7GU4SL1_rFEaRUWqY',
    '_uaProduct': 'Mozilla/5.0',
    '_uaLinuxOpen': '(Linux; Android',
    '_uaBuildLabel': ' Build/',
    '_uaBuildClose': ')',
    '_uaEngineLabel': ' AppleWebKit/',
    '_uaEngineTail': ' (KHTML, like Gecko)',
    '_uaChromeLabel': ' Chrome/',
    '_uaMobileSafari': ' Mobile Safari/',
    '_chromeVersion': '148.0.7730.86',
    '_webkitVersion': '537.36',
    '_jsInsetScript': jsInset,
    '_jsSeatScript': jsSeat,
    '_jsPlayScript': jsPlay,
  };

  final StringBuffer body = StringBuffer();
  values.forEach((String name, String plain) {
    final List<int> enc = conceal(plain);
    if (unfoldRunes(enc) != plain) {
      stderr.writeln('round-trip failed for $name');
      exitCode = 1;
    }
    body.write('const List<int> $name = ${_fmtArray(enc)};\n\n');
  });

  final String source = '''
import '../fold/rune_fold.dart';

// Sealed runes — written by tool/rune_seal.dart. Do not edit by hand.

$body
String openEndpointUrl() => unfoldRunes(_endpointUrl);
String openGcdBaseUrl() => unfoldRunes(_gcdBaseUrl);
String openAttributionKey() => unfoldRunes(_attributionKey);
String openMessagingProject() => unfoldRunes(_messagingProject);
String openRelaySecret() => unfoldRunes(_relaySecret);

String openUaProduct() => unfoldRunes(_uaProduct);
String openUaLinuxOpen() => unfoldRunes(_uaLinuxOpen);
String openUaBuildLabel() => unfoldRunes(_uaBuildLabel);
String openUaBuildClose() => unfoldRunes(_uaBuildClose);
String openUaEngineLabel() => unfoldRunes(_uaEngineLabel);
String openUaEngineTail() => unfoldRunes(_uaEngineTail);
String openUaChromeLabel() => unfoldRunes(_uaChromeLabel);
String openUaMobileSafari() => unfoldRunes(_uaMobileSafari);
String openChromeVersion() => unfoldRunes(_chromeVersion);
String openWebkitVersion() => unfoldRunes(_webkitVersion);

String openJsInsetScript() => unfoldRunes(_jsInsetScript);
String openJsSeatScript() => unfoldRunes(_jsSeatScript);
String openJsPlayScript() => unfoldRunes(_jsPlayScript);

String openGcdCallUrl(String applicationId, String deviceId) {
  final String base = openGcdBaseUrl();
  if (base.isEmpty) return '';
  return '\$base\$applicationId?device_id=\$deviceId&devkey=\${openAttributionKey()}';
}
''';

  File('lib/marble/tablet/sealed_runes.dart').writeAsStringSync(source);
  print('wrote lib/marble/tablet/sealed_runes.dart');
}

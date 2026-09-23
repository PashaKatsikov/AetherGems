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

  // Keyboard seating. The lift is recomputed from the field's live position
  // every pass (current rect plus whatever we already hold it up by) and is
  // applied without a CSS transition, so the measurement is always exact.
  // That way a page that scrolls itself after focus - which is what threw
  // the first portrait open - simply gets corrected on the next pass instead
  // of stacking a second displacement on ours.
  const String jsSeat = r'''
(function () {
  var MARK = '__k3Roost';
  if (window[MARK] && window[MARK].live) { return; }

  var LIMIT = 0.9;
  var SLACK = 4;
  var state = { part: 0, shell: null, base: '', lift: 0 };
  var frame = 0;

  function gapPx() {
    var v = (window.innerHeight * 0.015) | 0;
    if (v < 6) { return 6; }
    return v > 16 ? 16 : v;
  }
  function target() {
    var node = document.activeElement;
    if (!node || !node.tagName) { return null; }
    if (node.isContentEditable === true) { return node; }
    var tag = node.tagName.toLowerCase();
    return (tag === 'input' || tag === 'textarea' || tag === 'select') ? node : null;
  }
  function anchored(node) {
    var up = node.parentElement;
    while (up && up !== document.body) {
      if (getComputedStyle(up).position === 'fixed') { return up; }
      up = up.parentElement;
    }
    return null;
  }
  function keysTop() {
    var p = state.part > LIMIT ? LIMIT : state.part;
    return window.innerHeight * (1 - p);
  }
  function clear() {
    if (state.shell) { state.shell.style.transform = state.base; }
    state.shell = null;
    state.base = '';
    state.lift = 0;
  }
  function move(px) {
    if (px === state.lift) { return; }
    state.lift = px;
    var shift = 'translate3d(0px,' + (-px) + 'px,0px)';
    state.shell.style.transform = state.base ? (state.base + ' ' + shift) : shift;
  }
  function settle() {
    var node = target();
    if (!node || !(state.part > 0)) { clear(); return; }

    var shell = anchored(node);
    var top = keysTop();
    if (!shell) {
      clear();
      var under = node.getBoundingClientRect().bottom + gapPx() - top;
      if (under > SLACK) { window.scrollBy(0, under); }
      return;
    }
    if (shell !== state.shell) {
      clear();
      state.shell = shell;
      state.base = shell.style.transform || '';
    }
    // Resting bottom = where it sits right now plus the shift we are already
    // holding. No transition is in flight, so this reads true every pass.
    var rest = node.getBoundingClientRect().bottom + state.lift;
    var need = rest + gapPx() - top;
    move(need > SLACK ? need : 0);
  }
  function plan() {
    if (frame) { return; }
    frame = requestAnimationFrame(function () { frame = 0; settle(); });
  }
  function replan() {
    plan();
    setTimeout(plan, 120);
    setTimeout(plan, 320);
  }

  function roost(value) {
    state.part = value > 0 ? value : 0;
    if (!(state.part > 0)) {
      if (frame) { cancelAnimationFrame(frame); frame = 0; }
      clear();
      return;
    }
    plan();
  }
  roost.live = 1;
  window[MARK] = roost;

  document.addEventListener('focusin', replan, true);
  document.addEventListener('focusout', function () { setTimeout(plan, 0); }, true);
  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', plan);
    window.visualViewport.addEventListener('scroll', plan);
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

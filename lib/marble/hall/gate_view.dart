import 'dart:async';
import 'dart:io';
import 'dart:ui' show FlutterView;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../line/field_slide.dart';
import '../line/handset_mark.dart';
import '../line/page_hooks.dart';
import '../line/push_desk.dart';
import '../line/reach_tap.dart';
import '../line/slate_box.dart';
import '../tablet/court_spec.dart';
import 'quiet_view.dart';

class GateView extends StatefulWidget {
  const GateView({
    super.key,
    required this.url,
    required this.slate,
    required this.desk,
  });

  final String url;
  final SlateBox slate;
  final PushDesk desk;

  @override
  State<GateView> createState() => _GateViewState();
}

class _GateViewState extends State<GateView> with WidgetsBindingObserver {
  late final WebViewController _web;
  final FieldSlide _kb = FieldSlide();
  bool _spinner = true;
  bool _offlineShown = false;
  String? _lastMainFrame;
  int _retryCounter = 0;
  Timer? _dropDebounce;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Size? _lastPhysical;

  static const MethodChannel _uploadChannel = MethodChannel('gemwell/choose');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _enterImmersive();
    // The cutout is only there once the window has been laid out, and the
    // first frame can still report the pre-rotation one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readCutout();
      WidgetsBinding.instance.addPostFrameCallback((_) => _readCutout());
    });
    _buildController();

    widget.desk.onIncomingUrl = (String url) {
      if (mounted) _web.loadRequest(Uri.parse(url));
    };

    _connSub = ReachTap().statusStream.listen((List<ConnectivityResult> r) {
      final bool allNone = r.isNotEmpty &&
          r.every((ConnectivityResult e) => e == ConnectivityResult.none);
      if (!allNone) {
        _dropDebounce?.cancel();
        return;
      }
      _dropDebounce?.cancel();
      _dropDebounce = Timer(
        Duration(milliseconds: CourtSpec.reachDropDebounceMs),
        _showOffline,
      );
    });
  }

  void _enterImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _enterImmersive();
  }

  @override
  void didChangeMetrics() {
    _readCutout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _readCutout();
    });

    final FlutterView? view = _view();
    if (view == null) return;
    _kb.measure(view);

    final Size current = view.physicalSize;
    final Size? previous = _lastPhysical;
    _lastPhysical = current;
    if (previous == null) return;
    if ((previous.width > previous.height) == (current.width > current.height)) {
      return;
    }
    _enterImmersive();
  }

  FlutterView? _view() {
    if (mounted) {
      final FlutterView? local = View.maybeOf(context);
      if (local != null) return local;
    }
    final Iterable<FlutterView> views =
        WidgetsBinding.instance.platformDispatcher.views;
    return views.isEmpty ? null : views.first;
  }

  Future<void> _readCutout() async {
    final FlutterView? view = _view();
    if (view == null) return;
    await _kb.readCutout(view.devicePixelRatio);
    if (!mounted) return;
    // The cutout is what the keyboard share is measured against, so a late
    // notch reading has to be folded back in.
    _kb.measure(view);
  }

  void _buildController() {
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(HandsetMark.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _spinner = true);
        },
        onPageFinished: (_) async {
          if (mounted) setState(() => _spinner = false);
          _retryCounter = 0;
          await PageHooks.installAll(_web);
          // A page that loaded while the keyboard was already up starts out
          // with no idea how much room is left.
          if (_kb.share > 0) await _kb.cast();
        },
        onWebResourceError: _onError,
        onNavigationRequest: _onNavigate,
      ));

    _kb.bind(_web);
    _configureAndroid();
    _web.loadRequest(Uri.parse(widget.url));
  }

  void _onError(WebResourceError err) {
    if (err.isForMainFrame != true) return;

    final String desc = err.description.toLowerCase();
    final bool isLoop = desc.contains('too_many_redirects') ||
        desc.contains('too many redirects') ||
        err.errorCode == -1007 ||
        err.errorCode == -9;

    if (isLoop &&
        _lastMainFrame != null &&
        _retryCounter < CourtSpec.redirectLoopRetries) {
      _retryCounter++;
      _web.loadRequest(Uri.parse(_lastMainFrame!));
      return;
    }

    if (mounted) setState(() => _spinner = true);

    final bool isConnectivity = desc.contains('name_not_resolved') ||
        desc.contains('err_name_not_resolved') ||
        desc.contains('internet_disconnected') ||
        desc.contains('network_changed') ||
        err.errorCode == -105 ||
        err.errorCode == -106 ||
        err.errorCode == -21;

    if (isConnectivity) {
      _showOffline();
    } else {
      _guardOffline();
    }
  }

  NavigationDecision _onNavigate(NavigationRequest req) {
    final Uri? uri = Uri.tryParse(req.url);
    if (uri == null) return NavigationDecision.prevent;
    const Set<String> inApp = <String>{'http', 'https', 'about', 'data', 'blob'};
    if (inApp.contains(uri.scheme)) {
      if (req.isMainFrame) _lastMainFrame = req.url;
      return NavigationDecision.navigate;
    }
    _openExternally(uri);
    return NavigationDecision.prevent;
  }

  void _configureAndroid() {
    if (!Platform.isAndroid) return;
    if (_web.platform is! AndroidWebViewController) return;
    final AndroidWebViewController controller =
        _web.platform as AndroidWebViewController;

    controller.setMediaPlaybackRequiresUserGesture(false);
    controller.setOnPlatformPermissionRequest(
      (PlatformWebViewPermissionRequest r) => r.grant(),
    );
    controller.setOnShowFileSelector(_pickFiles);

    final AndroidWebViewCookieManager cookies = AndroidWebViewCookieManager(
      AndroidWebViewCookieManagerCreationParams
          .fromPlatformWebViewCookieManagerCreationParams(
        const PlatformWebViewCookieManagerCreationParams(),
      ),
    );
    cookies.setAcceptThirdPartyCookies(controller, true);
  }

  Future<List<String>> _pickFiles(FileSelectorParams params) async {
    try {
      final List<Object?>? picked = await _uploadChannel.invokeMethod<List<Object?>>(
        'choose',
        <String, Object>{
          'many': params.mode == FileSelectorMode.openMultiple,
          'kinds': params.acceptTypes.where((String t) => t.trim().isNotEmpty).toList(),
        },
      );
      if (picked == null) return const <String>[];
      return picked.whereType<String>().toList();
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> _openExternally(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _guardOffline() async {
    if (_offlineShown) return;
    final bool online = await ReachTap().canDialOut();
    if (online) return;
    _showOffline();
  }

  void _showOffline() {
    if (_offlineShown || !mounted) return;
    _offlineShown = true;
    final String current = _lastMainFrame ?? widget.url;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuietView(
          onRetryBuild: (_) => GateView(
            url: current,
            slate: widget.slate,
            desk: widget.desk,
          ),
        ),
      ),
    );
  }

  Future<void> _stepBack() async {
    if (await _web.canGoBack()) await _web.goBack();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dropDebounce?.cancel();
    _connSub?.cancel();
    _kb.dispose();
    widget.desk.onIncomingUrl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool landscape = mq.orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (!didPop) await _stepBack();
      },
      child: Scaffold(
        // The cutout padding reveals this behind the page, so the notch
        // band reads as solid black rather than navy.
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: ValueListenableBuilder<EdgeInsets>(
          valueListenable: _kb.cutout,
          builder: (BuildContext context, EdgeInsets cutout, Widget? _) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Padding(
                  padding: cutout,
                  // The page owns every pixel it is given: no Flutter inset
                  // reaches it, so the keyboard cannot shrink the viewport
                  // out from under the field being seated.
                  child: MediaQuery(
                    data: mq.removeViewInsets(removeBottom: true).copyWith(
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                    ),
                    child: WebViewWidget(controller: _web),
                  ),
                ),
                if (_spinner && !landscape)
                  const ColoredBox(
                    color: Color(0x99071226),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6AE7FF)),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

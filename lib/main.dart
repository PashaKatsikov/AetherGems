import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'marble/line/attr_gather.dart';
import 'marble/line/handset_mark.dart';
import 'marble/line/push_desk.dart';
import 'marble/line/reach_tap.dart';
import 'marble/line/ruling_post.dart';
import 'marble/line/slate_box.dart';
import 'marble/marble_gate.dart';
import 'marble/tablet/court_spec.dart';
import 'theme.dart';
import 'ui/boot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF071226),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await HandsetMark.prime();

  final SlateBox slate = SlateBox();
  await slate.prime();

  final ReachTap reach = ReachTap();
  final AttrGather gather = AttrGather();
  final RulingPost ruling = RulingPost(slate);
  final PushDesk desk = PushDesk(slate);
  final MarbleGate gate = MarbleGate(
    slate: slate,
    reach: reach,
    gather: gather,
    ruling: ruling,
    desk: desk,
  );

  runApp(AetherApp(gate: gate, slate: slate, desk: desk));
}

class AetherApp extends StatefulWidget {
  const AetherApp({
    super.key,
    required this.gate,
    required this.slate,
    required this.desk,
  });

  final MarbleGate gate;
  final SlateBox slate;
  final PushDesk desk;

  @override
  State<AetherApp> createState() => _AetherAppState();
}

class _AetherAppState extends State<AetherApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: CourtSpec.displayName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: BootPage(gate: widget.gate, slate: widget.slate, desk: widget.desk),
    );
  }
}

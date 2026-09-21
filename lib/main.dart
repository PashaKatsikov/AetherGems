import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'ui/boot.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF0A1628),
  ));
  runApp(const AetherApp());
}

class AetherApp extends StatelessWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aether Gems',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const BootPage(),
    );
  }
}

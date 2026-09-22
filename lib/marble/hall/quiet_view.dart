import 'package:flutter/material.dart';

import '../../ui/gem_pills.dart';
import '../tablet/plates.dart';

class QuietView extends StatefulWidget {
  const QuietView({super.key, required this.onRetryBuild});

  final WidgetBuilder onRetryBuild;

  @override
  State<QuietView> createState() => _QuietViewState();
}

class _QuietViewState extends State<QuietView> {
  bool _spinning = false;

  Future<void> _retry() async {
    if (_spinning) return;
    setState(() => _spinning = true);
    await Future<void>.delayed(const Duration(milliseconds: 880));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: widget.onRetryBuild),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final Size size = MediaQuery.of(context).size;
    final String bg = landscape ? Plates.quietWide : Plates.quietTall;

    final Widget body = Scaffold(
      backgroundColor: const Color(0xFF071226),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(bg, fit: BoxFit.cover),
          Positioned(
            left: 0,
            right: 0,
            bottom: size.height * (landscape ? 0.07 : 0.09),
            child: Center(
              child: _spinning
                  ? const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6AE7FF)),
                      ),
                    )
                  : GemPill(
                      label: 'Retry',
                      width: landscape ? size.width * 0.28 : size.width * 0.52,
                      onTap: _retry,
                    ),
            ),
          ),
        ],
      ),
    );

    if (!landscape) return body;
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: body,
    );
  }
}

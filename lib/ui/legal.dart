import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app.dart';
import '../theme.dart';
import 'chrome.dart';

class LegalPage extends StatefulWidget {
  const LegalPage();

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  WebViewController? _ctl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ctl != null) return;
    final bag = Store.of(context);
    final ctl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF071226))
      ..loadRequest(Uri.parse(bag.legalUrl));
    _ctl = ctl;
  }

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return ColoredBox(
      color: const Color(0xFF071226),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: C.ink,
              child: Row(
                children: [
                  BackOrb(onTap: bag.closeLegal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bag.legalTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Pal.heading.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ctl == null
                  ? const Center(child: CircularProgressIndicator(color: C.gold))
                  : WebViewWidget(controller: _ctl!),
            ),
          ],
        ),
      ),
    );
  }
}

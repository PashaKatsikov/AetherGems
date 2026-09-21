import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app.dart';
import '../theme.dart';
import 'chrome.dart';

const _whiteCss = r'''
(function() {
  var css = "html,body{background:#ffffff !important;color:#1b1b1b !important;color-scheme:only light !important;}"
    + "body,body *{background-color:#ffffff !important;color:#1b1b1b !important;}"
    + "a,a *{color:#0b57d0 !important;}";
  var old = document.getElementById('aether-white');
  if (old && old.parentNode) old.parentNode.removeChild(old);
  var s = document.createElement('style');
  s.id = 'aether-white';
  s.appendChild(document.createTextNode(css));
  (document.head || document.documentElement).appendChild(s);
  document.documentElement.style.background = '#ffffff';
  document.documentElement.style.colorScheme = 'only light';
  if (document.body) {
    document.body.style.background = '#ffffff';
    document.body.style.color = '#1b1b1b';
  }
})();
''';

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
    final ctl = WebViewController();
    ctl.setJavaScriptMode(JavaScriptMode.unrestricted);
    ctl.setBackgroundColor(Colors.white);
    ctl.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) async {
          if (!bag.legalPrivacy) return;
          for (final wait in [0, 200, 600, 1200]) {
            await Future<void>.delayed(Duration(milliseconds: wait));
            try {
              await ctl.runJavaScript(_whiteCss);
            } catch (_) {}
          }
        },
      ),
    );
    ctl.loadRequest(Uri.parse(bag.legalUrl));
    _ctl = ctl;
  }

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return ColoredBox(
      color: Colors.white,
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

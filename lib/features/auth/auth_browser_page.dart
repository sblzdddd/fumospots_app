import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/services/fumo_client_error.dart';
import 'auth_controller.dart';
import 'auth_exception.dart';
import 'auth_flow.dart';

class AuthBrowserPage extends StatefulWidget {
  const AuthBrowserPage({
    super.key,
    required this.initialUrl,
    required this.callbackUri,
    this.codeVerifier,
    this.title = 'Sign in',
  });

  final Uri initialUrl;
  final Uri callbackUri;
  final String? codeVerifier;
  final String title;

  @override
  State<AuthBrowserPage> createState() => _AuthBrowserPageState();
}

class _AuthBrowserPageState extends State<AuthBrowserPage> {
  late final WebViewController _controller;
  Timer? _coverTimer;
  String? _pageUrl;
  String? _error;
  String? _pageError;
  bool _ready = false;
  bool _done = false;
  bool _exchanging = false;
  bool _hidingSite = false;
  int _progress = 0;

  static const _watchScript = r'''
(function() {
  if (window.__fumoAuthWatch) return;
  window.__fumoAuthWatch = true;
  function send(prefix, value) {
    if (!value) return;
    try { FumoAuth.postMessage(prefix + value); } catch (e) {}
  }
  function reportLocation() {
    var href = String(window.location.href || '');
    if (
      href.indexOf('access_token=') !== -1 ||
      href.indexOf('refresh_token=') !== -1 ||
      href.indexOf('code=') !== -1 ||
      href.indexOf('error=') !== -1 ||
      href.indexOf('error_description=') !== -1
    ) {
      send('loc:', href);
    }
  }
  function reportStore() {
    try {
      var keys = Object.keys(localStorage);
      for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (key.indexOf('sb-') === 0 && key.indexOf('auth-token') !== -1) {
          var value = localStorage.getItem(key) || '';
          if (value.indexOf('access_token') !== -1) send('store:', value);
        }
      }
    } catch (e) {}
  }
  reportLocation();
  reportStore();
  window.addEventListener('hashchange', function() {
    reportLocation();
    setTimeout(reportStore, 250);
  });
  var ticks = 0;
  var timer = setInterval(function() {
    ticks += 1;
    reportLocation();
    if (ticks % 2 === 0) reportStore();
    if (ticks >= 40) clearInterval(timer);
  }, 400);
})();
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_open());
  }

  @override
  void dispose() {
    _coverTimer?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setUserAgent(_userAgent());
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigation,
          onPageStarted: (url) {
            _pageUrl = url;
            unawaited(_inject());
          },
          onPageFinished: (url) {
            _pageUrl = url;
            unawaited(_inject());
          },
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) {
              _pageUrl = url;
              _considerUrl(url);
            }
          },
          onWebResourceError: (error) {
            if (_done || error.isForMainFrame != true || !mounted) {
              return;
            }
            setState(() => _pageError = error.description);
          },
        ),
      );
      await _controller.addJavaScriptChannel(
        'FumoAuth',
        onMessageReceived: (message) => _onJs(message.message),
      );
      await WebViewCookieManager().clearCookies();
      await _controller.clearCache();
      await _controller.clearLocalStorage();
      await _controller.loadRequest(widget.initialUrl);
      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _ready = true;
          _error = 'Could not open the sign-in page. $error';
        });
      }
    }
  }

  String _userAgent() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1';
      case TargetPlatform.macOS:
        return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15';
      default:
        return 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';
    }
  }

  Future<void> _inject() async {
    try {
      await _controller.runJavaScript(_watchScript);
    } catch (_) {}
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    if (!request.isMainFrame) {
      return NavigationDecision.navigate;
    }
    final uri = Uri.tryParse(request.url);
    if (uri == null || !sameAuthOrigin(uri, widget.callbackUri)) {
      return NavigationDecision.navigate;
    }
    _showSiteCover();
    final callback = AuthCallback.tryParse(request.url);
    if (callback != null &&
        (callback.hasCode || callback.hasError || callback.hasSessionTokens)) {
      _handle(callback);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _onJs(String message) {
    if (message.startsWith('loc:')) {
      _considerUrl(message.substring(4));
      return;
    }
    if (message.startsWith('store:')) {
      _considerStore(message.substring(6));
    }
  }

  void _considerUrl(String raw) {
    if (_done) {
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || !sameAuthOrigin(uri, widget.callbackUri)) {
      return;
    }
    final callback = AuthCallback.tryParse(raw);
    if (callback == null) {
      return;
    }
    if (callback.hasSessionTokens || callback.hasCode || callback.hasError) {
      _showSiteCover();
      _handle(callback);
    }
  }

  void _considerStore(String raw) {
    if (_done) {
      return;
    }
    final page = Uri.tryParse(_pageUrl ?? '');
    if (page == null || !sameAuthOrigin(page, widget.callbackUri)) {
      return;
    }
    try {
      Object? decoded = jsonDecode(raw);
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is! Map) {
        return;
      }
      final json = Map<String, dynamic>.from(decoded);
      final nested = json['currentSession'] ?? json['session'];
      final source = nested is Map
          ? Map<String, dynamic>.from(nested)
          : json;
      final access = source['access_token'];
      final refresh = source['refresh_token'];
      if (access is! String ||
          refresh is! String ||
          access.isEmpty ||
          refresh.isEmpty) {
        return;
      }
      _handle(
        AuthCallback(
          accessToken: access,
          refreshToken: refresh,
          expiresAt: _asInt(source['expires_at']),
          expiresIn: _asInt(source['expires_in']),
        ),
      );
    } catch (_) {}
  }

  int? _asInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }

  void _showSiteCover() {
    if (_hidingSite || !mounted) {
      return;
    }
    setState(() => _hidingSite = true);
    _coverTimer ??= Timer(const Duration(seconds: 15), () {
      if (!mounted || _done) {
        return;
      }
      setState(() {
        _hidingSite = false;
        _exchanging = false;
        _error = 'Could not read the login session from the website.';
      });
    });
  }

  void _handle(AuthCallback callback) {
    if (_done) {
      return;
    }
    if (callback.hasError && !callback.hasSessionTokens) {
      _done = true;
      _coverTimer?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _exchanging = false;
        _hidingSite = false;
        _error = callback.errorDescription;
      });
      return;
    }
    if (!callback.hasSessionTokens && !callback.hasCode) {
      return;
    }
    _done = true;
    _coverTimer?.cancel();
    if (mounted) {
      setState(() {
        _exchanging = true;
        _hidingSite = true;
        _error = null;
      });
    }
    unawaited(_finish(callback));
  }

  Future<void> _finish(AuthCallback callback) async {
    try {
      final auth = GetIt.instance<AuthController>();
      if (callback.hasSessionTokens) {
        await auth.completeImplicitSession(
          accessToken: callback.accessToken!,
          refreshToken: callback.refreshToken!,
          expiresAt: callback.expiresAt,
          expiresIn: callback.expiresIn,
        );
      } else if (callback.hasCode && widget.codeVerifier != null) {
        await auth.completeAuthorizationCode(
          code: callback.code!,
          codeVerifier: widget.codeVerifier!,
        );
      } else {
        throw const AuthException(
          'This email link could not be completed in the app. Request a new link and paste it here.',
        );
      }
      if (mounted) {
        Navigator.of(context).pop(const AuthBrowserResult(succeeded: true));
      }
    } on FumoClientError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _exchanging = false;
        _hidingSite = false;
        _error = error.message;
      });
    }
  }

  void _close() {
    Navigator.of(context).pop(
      _error == null
          ? null
          : AuthBrowserResult(succeeded: false, message: _error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Close',
          onPressed: _close,
          icon: const BackButtonIcon(),
        ),
      ),
      body: Stack(
        children: [
          if (_ready) WebViewWidget(controller: _controller),
          if (_progress > 0 && _progress < 100 && _error == null)
            LinearProgressIndicator(value: _progress / 100),
          if (_pageError != null && !_hidingSite && _error == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: cs.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _pageError!,
                    style: TextStyle(color: cs.onErrorContainer),
                  ),
                ),
              ),
            ),
          if (_hidingSite || _exchanging || !_ready)
            ColoredBox(
              color: cs.surface,
              child: const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          if (_error != null)
            ColoredBox(
              color: cs.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _close, child: const Text('Close')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../core/app_config.dart';
import '../core/app_theme.dart';
import '../core/location_permission.dart';
import '../widgets/brand_mark.dart';
import '../widgets/status_panel.dart';

/// Android / iOS shell: hosts the live FIZ Price web app inside a WebView.
///
/// The device needs a network connection for this screen; the web build uses
/// `web_launcher_screen.dart` instead because the site forbids framing.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// `target="_blank"` links would be swallowed by the WebView, so the target
  /// attribute is stripped and every link opens in the same view.
  static const String _stripBlankTargetsScript = '''
(function () {
  try {
    var links = document.querySelectorAll('a[target="_blank"]');
    for (var i = 0; i < links.length; i++) { links[i].removeAttribute('target'); }
  } catch (error) {}
})();
''';

  final WebViewController _controller = WebViewController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  double _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isOffline = false;
  String _errorDetail = '';
  DateTime _lastBackPressedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _configureWebView();
    _watchConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- WebView --

  Future<void> _configureWebView() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.white);
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          _setStateSafely(() => _progress = progress / 100);
        },
        onPageStarted: (String url) {
          _setStateSafely(() {
            _isLoading = true;
            _hasError = false;
          });
        },
        onPageFinished: (String url) async {
          _setStateSafely(() => _isLoading = false);
          await _controller.runJavaScript(_stripBlankTargetsScript);
        },
        onWebResourceError: _onWebResourceError,
        onNavigationRequest: _onNavigationRequest,
      ),
    );
    await _configureAndroidWebView();
    await _loadApp();
  }

  Future<void> _configureAndroidWebView() async {
    final Object platform = _controller.platform;
    if (platform is! AndroidWebViewController) return;

    await platform.setMediaPlaybackRequiresUserGesture(false);
    await platform.setGeolocationEnabled(true);
    await platform.setGeolocationPermissionsPromptCallbacks(
      onShowPrompt: _onGeolocationPrompt,
    );
  }

  /// Android hands geolocation to web content only once the host app is allowed
  /// to use the location, so the system permission is requested first.
  Future<GeolocationPermissionsResponse> _onGeolocationPrompt(
    GeolocationPermissionsRequestParams request,
  ) async {
    final bool granted = await LocationPermission.ensureGranted();
    return GeolocationPermissionsResponse(allow: granted, retain: true);
  }

  void _onWebResourceError(WebResourceError error) {
    // Sub-resource failures (images, analytics) must not blank out the app.
    if (error.isForMainFrame == false) return;
    _errorDetail = error.description;
    _setStateSafely(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final Uri? uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    if (uri.isScheme('http') || uri.isScheme('https')) {
      return NavigationDecision.navigate;
    }

    // tel:, mailto:, sms:, whatsapp:, upi:, intent: … belong to other apps.
    _openExternally(uri);
    return NavigationDecision.prevent;
  }

  // ------------------------------------------------------------------ state --

  void _setStateSafely(VoidCallback mutate) {
    if (!mounted) return;
    setState(mutate);
  }

  void _watchConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final bool isOnline = results.any(
          (ConnectivityResult result) => result != ConnectivityResult.none,
        );
        if (_isOffline == !isOnline) return;

        _setStateSafely(() => _isOffline = !isOnline);
        if (isOnline && _hasError) {
          _loadApp();
        }
      },
    );
  }

  Future<void> _loadApp() async {
    _setStateSafely(() {
      _hasError = false;
      _isLoading = true;
    });
    await _controller.loadRequest(Uri.parse(AppConfig.appUrl));
    _setStateSafely(() => _isOffline = false);
  }

  // --------------------------------------------------------------- actions --

  Future<void> _openExternally(Uri uri) async {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text('No app installed to open ${uri.scheme}: links.'),
        ),
      );
    }
  }

  Future<void> _openCurrentPageInBrowser() async {
    final String? currentUrl = await _controller.currentUrl();
    await _openExternally(Uri.parse(currentUrl ?? AppConfig.appUrl));
  }

  Future<void> _requestLocationPermission() async {
    final bool granted = await LocationPermission.ensureGranted();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Location access allowed.'
              : 'Location access denied. Enable it from the app settings.',
        ),
        action: granted
            ? null
            : SnackBarAction(
                label: 'Settings',
                onPressed: LocationPermission.openSettings,
              ),
      ),
    );
    if (granted) {
      await _controller.reload();
    }
  }

  Future<void> _handleSystemBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (!mounted) return;

    final DateTime now = DateTime.now();
    if (now.difference(_lastBackPressedAt) > const Duration(seconds: 2)) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await SystemNavigator.pop();
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: AppConfig.version,
      applicationIcon: const BrandMark(size: 48),
      children: <Widget>[
        const SizedBox(height: 8),
        const Text(
          'Prices, offers and product updates from ${AppConfig.companyName}, '
          'served live from ${AppConfig.appHost}.',
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- UI ---

  @override
  Widget build(BuildContext context) {
    final bool showStatusPanel = _isOffline || _hasError;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: <Widget>[
            Positioned.fill(child: WebViewWidget(controller: _controller)),
            if (showStatusPanel)
              Positioned.fill(
                child: StatusPanel(
                  icon: _isOffline
                      ? Icons.wifi_off_rounded
                      : Icons.cloud_off_rounded,
                  title: _isOffline ? 'No internet connection' : 'Page did not load',
                  message: _isOffline
                      ? 'Reconnect to the internet to keep browsing live prices. '
                            'The app reloads by itself once you are back online.'
                      : 'We could not reach ${AppConfig.appHost}. '
                            '${_errorDetail.isEmpty ? '' : '($_errorDetail)'}',
                  onRetry: _loadApp,
                  onSecondary: _openCurrentPageInBrowser,
                  secondaryLabel: 'Open in browser',
                ),
              ),
            if (_isLoading && !showStatusPanel)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress <= 0 || _progress >= 1 ? null : _progress,
                  minHeight: 3,
                  color: AppColors.brandYellow,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 12,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.brandGradient),
      ),
      title: Row(
        children: <Widget>[
          const BrandMark(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  AppConfig.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                Text(
                  AppConfig.appHost,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadApp,
        ),
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (String action) {
            switch (action) {
              case 'browser':
                _openCurrentPageInBrowser();
              case 'location':
                _requestLocationPermission();
              case 'about':
                _showAboutDialog();
            }
          },
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'browser',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.open_in_browser_rounded),
                title: Text('Open in browser'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'location',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.my_location_rounded),
                title: Text('Location access'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'about',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline_rounded),
                title: Text('About'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

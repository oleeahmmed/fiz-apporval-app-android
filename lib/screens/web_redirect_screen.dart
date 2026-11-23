import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_config.dart';
import '../core/app_theme.dart';
import '../widgets/brand_mark.dart';

/// Web build shell.
///
/// `web/index.html` already navigates to [AppConfig.appUrl] before Flutter boots.
/// This screen is the fallback for the case where the app is opened directly
/// (deep link, cached shell, service worker): it hands the browser over at once
/// and only paints the brand gradient for the instant that takes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame, so the navigation is not dropped on slow devices.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openApp());
  }

  Future<void> _openApp() async {
    await launchUrl(
      Uri.parse(AppConfig.appUrl),
      webOnlyWindowName: '_self',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const BrandMark(size: 96),
              const SizedBox(height: 20),
              Text(
                'Opening ${AppConfig.appName}…',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

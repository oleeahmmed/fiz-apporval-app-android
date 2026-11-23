import 'package:material_ui/material_ui.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FizPriceApp());
}

class FizPriceApp extends StatelessWidget {
  const FizPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}

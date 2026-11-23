import 'package:fizprice/core/app_config.dart';
import 'package:fizprice/core/app_theme.dart';
import 'package:fizprice/widgets/status_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('the app points at the live FIZ Price web app', () {
    expect(AppConfig.appUrl, 'https://www.fizbd.com/fizPriceApp/');
    expect(AppConfig.appHost, 'www.fizbd.com');
  });

  test('the theme uses the brand colour', () {
    expect(buildAppTheme().colorScheme.primary, AppColors.brandOrange);
  });

  testWidgets('the offline panel offers a retry', (WidgetTester tester) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: StatusPanel(
            icon: Icons.wifi_off_rounded,
            title: 'No internet connection',
            message: 'The app reloads by itself once you are back online.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('No internet connection'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });
}

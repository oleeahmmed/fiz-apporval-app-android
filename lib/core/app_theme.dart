import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Brand palette sampled from the FIZ / Faiza logo.
abstract final class AppColors {
  static const Color brandOrange = Color(0xFFF5821F);
  static const Color brandYellow = Color(0xFFFDB913);
  static const Color brandInk = Color(0xFF1C1C1C);
  static const Color brandNavy = Color(0xFF16233F);
  static const Color canvas = Color(0xFFFFFBF4);

  static const LinearGradient brandGradient = LinearGradient(
    colors: <Color>[brandYellow, brandOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandOrange,
  ).copyWith(
    primary: AppColors.brandOrange,
    onPrimary: Colors.white,
    secondary: AppColors.brandYellow,
    surface: Colors.white,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.brandOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

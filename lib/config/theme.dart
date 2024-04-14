import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const primary = Color(0xff0d6efd);
  static const onPrimary = Colors.white;
  static const secondary = Color(0xff0257d5);
  static const onSecondary = Colors.white;
  static const background = Colors.white;
  static const onBackground = Colors.black;
  static const darkSurface = Color(0xff151718);
  static const ondarkSurfaceInActive = Color(0xff9ba1a6);
  static const ondarkSurfaceActive = Colors.white;
  static const lightSurface = Color(0xff313538);
  static const onlightSurface = Colors.white;
}

ThemeData get appTheme => ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
      ),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.ondarkSurfaceActive,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            AppColors.lightSurface,
          ),
          side: const MaterialStatePropertyAll(
            BorderSide(
              color: Color(0xff4c5155),
            ),
          ),
          foregroundColor:
              const MaterialStatePropertyAll(AppColors.onlightSurface),
        ),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              MaterialStatePropertyAll(AppColors.ondarkSurfaceActive),
        ),
      ),
    );

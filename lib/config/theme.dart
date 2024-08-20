import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = NEARColors.blue;
  static const onPrimary = NEARColors.white;
  static const secondary = NEARColors.purple;
  static const onSecondary = NEARColors.white;
  static const background = NEARColors.white;
  static const onBackground = NEARColors.black;
  static const lightSurface = NEARColors.grey;
  static const onlightSurface = NEARColors.white;
}

class NEARColors {
  static const Color blue = Color(0xFF5F8AFA);
  static const Color lilac = Color(0xFFA463B0);
  static const Color purple = Color(0xFF6B6EF9);
  static const Color aqua = Color(0xFF4FD1D9);
  static const Color green = Color(0xFFAAD055);
  static const Color gold = Color(0xFFFFC860);
  static const Color orange = Color(0xFFE3935B);
  static const Color red = Color(0xFFDB5555);
  static const Color black = Color(0xFF262626);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFA7A7A7);
  static const Color slate = Color(0xFF3F4246);
}

ThemeData get appTheme => ThemeData(
      textTheme: GoogleFonts.manropeTextTheme(),
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
        backgroundColor: NEARColors.black,
        foregroundColor: NEARColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          side: const BorderSide(
            color: Color(0xff4c5155),
          ),
          foregroundColor: AppColors.onlightSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8).r),
          enableFeedback: true,
        ),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: NEARColors.black,
        surfaceTintColor: Colors.transparent,
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll(NEARColors.white),
        ),
      ),
    );

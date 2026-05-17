import 'package:flutter/material.dart';


enum AppMode { light, dark }

class AppColors extends ThemeExtension<AppColors> {
  final Color primary; // svelniai geltona (bloku backgroundai)
  final Color background;
  final Color background2; // korteliu fonas
  final Color intenseColor; // tik lygio spalva
  final Color appBarUnpickedColor; // secondary text
  final Color textColor;


  const AppColors({
    required this.primary,
    required this.background,
    required this.background2,
    required this.intenseColor,
    required this.appBarUnpickedColor,
    required this.textColor,


  });


  static const light = AppColors(
    primary: Color(0xFFFFEAC9),
    background: Color(0xFFEAEAEA),
    background2: Color(0xFFF6F5F5),
    intenseColor: Color(0xFFFFC963),
    appBarUnpickedColor: Color(0xFF999999),
    textColor: Color(0xFF000000),

  );

  static const dark = AppColors(
    primary: Color(0xFFA679FF),
    background: Color(0xFF121212),
    background2: Color(0xFF1D1D1D),
    intenseColor: Color(0xFF5848EA),
    appBarUnpickedColor: Color(0xFFD4D4D4),
    textColor: Color(0xFFF6F5F5),

  );



  // ThemeExtension boilerplate
  @override
  AppColors copyWith({Color? primary, Color? background, Color? background2,
    Color? levelColor, Color? appBarUnpickedColor, Color? textColor,
    }) {
    return AppColors(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      background2: background2 ?? this.background2,
      intenseColor: levelColor ?? this.intenseColor,
      appBarUnpickedColor: appBarUnpickedColor ?? this.appBarUnpickedColor,
      textColor: textColor ?? this.textColor,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) => this;

}

class AppTheme {
  static ThemeData of(AppMode mode) {
    final colors = switch (mode) {
      AppMode.light  => AppColors.light,
      AppMode.dark   => AppColors.dark,
    };

    final brightness = mode == AppMode.light
        ? Brightness.light
        : Brightness.dark;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.background2,
      dividerColor: colors.background,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textColor,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.background2,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.appBarUnpickedColor,
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: Colors.black,
        secondary: colors.primary,
        onSecondary: Colors.black,
        surface: colors.background2,
        onSurface: colors.textColor,
        error: Colors.red,
        onError: Colors.white,
      ),
    );

  }

}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

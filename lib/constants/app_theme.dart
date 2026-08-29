import 'package:flutter/material.dart';
// all the app colours in one place so they're easy to tweak
class AppColors {
  AppColors._(); // no instances of this, just static colours

  // brand
  static const Color primaryOrange = Color(0xFFE87722); // "Medi" logo text
  static const Color primaryPurple = Color(0xFF5847A8); // "Buddy" logo text

  // backgrounds
  static const Color background = Color(0xFFFFF0EF); // page background
  static const Color statusBar = Color(0xFFC9AEAD); // status bar area
  static const Color cardSurface = Colors.white;
  static const Color nextMedCard = Color(0xFFF5DDD8); // peach hero card
  static const Color bottomNavBg = Color(0xFFFDE8E8); // bottom nav bar

  // text
  static const Color textDark = Color(0xFF2D1B00);
  static const Color textMedium = Color(0xFF6B5B52);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color linkColor = Color(0xFF5847A8);

  // buttons / inputs
  static const Color buttonDark = Color(0xFF1A0000); // main button colour
  static const Color buttonOrange = Color(0xFFE87722); // secondary button
  static const Color inputBorder = Color(0xFFE0D5D0);
  static const Color divider = Color(0xFFEEE0DE);

  // badges
  static const Color takenBadge = Color(0xFF4CAF50); // green
  static const Color soonBadge = Color(0xFF9C7FC5); // lavender
  static const Color lowStockBadge = Color(0xFFFF9800); // amber

  // progress bar colours
  static const Color progressGreen = Color(0xFF4CAF50);
  static const Color progressBlue = Color(0xFF2196F3);
  static const Color progressYellow = Color(0xFFFFEB3B);
  static const Color progressTrack = Color(0xFFE0D5D0);
}
// text styles used across the app
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle logoMedi = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryOrange,
    letterSpacing: -0.5,
  );

  static const TextStyle logoBuddy = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryPurple,
    letterSpacing: -0.5,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textMedium,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textMedium,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    color: AppColors.linkColor,
    decoration: TextDecoration.underline,
  );
}
// same input styling for every text field in the app
InputDecoration appInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textMedium),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}
// builds the app theme
class AppTheme {
  AppTheme._();

  // takes the user's saved accent colour so buttons/nav/FABs all match
  // whatever colour they picked in settings instead of one fixed colour
  static ThemeData buildTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        background: AppColors.background,
        primary: accentColor,
        secondary: AppColors.primaryPurple,
      ),
      // ElevatedButton defaults to the dark pill style used throughout
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // TextButton – used for "Forgot password?", "Register here", etc.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.linkColor,
          textStyle: const TextStyle(
            fontSize: 14,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavBg,
        selectedItemColor: accentColor,
        unselectedItemColor: AppColors.textMedium,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

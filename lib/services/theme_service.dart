import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';

class ThemeService {
  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme);
  }

  Future<Color> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('selectedTheme');

    if (theme == 'blue') return Colors.blue;
    if (theme == 'green') return Colors.green;
    if (theme == 'purple') return AppColors.primaryPurple;
    if (theme == 'red') return Colors.red;

    return AppColors.primaryOrange; // default — MediBuddy's brand colour
  }
}

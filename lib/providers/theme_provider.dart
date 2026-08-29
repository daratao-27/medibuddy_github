import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../constants/app_theme.dart';
import '../services/theme_service.dart';

final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

final themeProvider = StateNotifierProvider<ThemeController, Color>((ref) {
  final service = ref.read(themeServiceProvider);
  return ThemeController(service);
});

class ThemeController extends StateNotifier<Color> {
  final ThemeService service;

  // load whatever theme colour was saved last time
  ThemeController(this.service) : super(AppColors.primaryOrange) {
    loadTheme();
  }

  Future<void> loadTheme() async {
    state = await service.getTheme();
  }

  Future<void> setTheme(Color color, String name) async {
    state = color;
    await service.setTheme(name);
  }
}

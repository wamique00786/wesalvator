import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeMode', mode.index);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int? themeIndex = prefs.getInt('themeMode');
    _themeMode = ThemeMode.values[themeIndex ?? 0];
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'dark_mode.dart';
import 'light_mode.dart'; // ✅ FIXED: file name was 'light_model.dart'

class ThemeProvider extends ChangeNotifier {
  // Initially, use light mode
  ThemeData _themeData = lightMode;

  // Get current theme
  ThemeData get themeData => _themeData;

  // Check if current theme is dark mode
  bool get isDarkMode => _themeData == darkMode;

  // Set theme
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  // Toggle between light and dark mode
  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}

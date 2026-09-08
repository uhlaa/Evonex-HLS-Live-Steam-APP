// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dark_mode.dart';
// import 'light_mode.dart';

// class ThemeProvider extends ChangeNotifier {
//   static const _themeKey = 'isDarkMode';

//   ThemeData _themeData = lightMode;
//   ThemeData get themeData => _themeData;

//   bool get isDarkMode => _themeData == darkMode;

//   ThemeProvider() {
//     _loadTheme(); // 🔑 app start এ load হবে
//   }

//   Future<void> _loadTheme() async {
//     final prefs = await SharedPreferences.getInstance();
//     final isDark = prefs.getBool(_themeKey) ?? false;
//     _themeData = isDark ? darkMode : lightMode;
//     notifyListeners();
//   }

//   Future<void> toggleTheme() async {
//     final prefs = await SharedPreferences.getInstance();

//     if (_themeData == lightMode) {
//       _themeData = darkMode;
//       await prefs.setBool(_themeKey, true);
//     } else {
//       _themeData = lightMode;
//       await prefs.setBool(_themeKey, false);
//     }

//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dark_mode.dart';
import 'light_mode.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'isDarkMode';


  ThemeData _themeData = darkMode;
  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool(_themeKey) ?? true;

    _themeData = isDark ? darkMode : lightMode;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (_themeData == lightMode) {
      _themeData = darkMode;
      await prefs.setBool(_themeKey, true);
    } else {
      _themeData = lightMode;
      await prefs.setBool(_themeKey, false);
    }

    notifyListeners();
  }
}

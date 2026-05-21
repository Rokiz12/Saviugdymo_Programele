import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  AppMode _mode = AppMode.light;
  AppMode get mode => _mode;

  void setMode(AppMode mode) {
    _mode = mode;
    notifyListeners();
  }
}
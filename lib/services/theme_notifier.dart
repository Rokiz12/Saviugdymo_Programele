import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  AppMode _mode = AppMode.light;
  AppMode get mode => _mode;

  Future<void> loadFromDb(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final data = doc.data();
    final themeStr = data?['settings']?['theme'] as String?;
    final newMode = (themeStr == 'dark') ? AppMode.dark : AppMode.light;

    if (newMode != _mode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  Future<void> setMode(String userId, AppMode mode) async {
    _mode = mode;
    notifyListeners();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({
      'settings': {
        'theme': mode == AppMode.dark ? 'dark' : 'light',
      }
    }, SetOptions(merge: true));
  }
}
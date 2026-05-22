import 'package:flutter/foundation.dart';

enum AppLanguage { lt, en }

class LanguageNotifier extends ChangeNotifier {
  AppLanguage _language = AppLanguage.lt;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }

  String t(String key) {
    final map = _translations[key];
    if (map == null) return key;
    return map[_language] ?? key;
  }

  static const Map<String, Map<AppLanguage, String>> _translations = {
    // Bottom navigation
    'nav_avatar': {AppLanguage.lt: 'Avataras', AppLanguage.en: 'Avatar'},
    'nav_statistics': {AppLanguage.lt: 'Statistikos', AppLanguage.en: 'Statistics'},
    'nav_habits': {AppLanguage.lt: 'Įpročiai', AppLanguage.en: 'Habits'},
    'nav_diary': {AppLanguage.lt: 'Dienoraštis', AppLanguage.en: 'Diary'},

    // Settings
    'settings_title': {AppLanguage.lt: 'Nustatymai', AppLanguage.en: 'Settings'},
    'profile_title': {AppLanguage.lt: 'Profilis', AppLanguage.en: 'Profile'},
    'name_label': {AppLanguage.lt: 'Vardas', AppLanguage.en: 'Name'},
    'email_label': {AppLanguage.lt: 'El. paštas', AppLanguage.en: 'Email'},
    'theme_title': {AppLanguage.lt: 'Tema', AppLanguage.en: 'Theme'},
    'language_title': {AppLanguage.lt: 'Kalba', AppLanguage.en: 'Language'},
    'premium_title': {AppLanguage.lt: 'Prenumerata', AppLanguage.en: 'Subscription'},
    'premium_activate': {AppLanguage.lt: 'Aktyvuoti', AppLanguage.en: 'Activate'},

    'account_title': {AppLanguage.lt: 'Paskyra', AppLanguage.en: 'Account'},
    'redo_questionnaire': {AppLanguage.lt: 'Perdaryti norų klausimyną', AppLanguage.en: 'Redo questionnaire'},
    'logout': {AppLanguage.lt: 'Atsijungti', AppLanguage.en: 'Logout'},
    'delete_account': {AppLanguage.lt: 'Ištrinti paskyrą', AppLanguage.en: 'Delete account'},
    'delete_confirm_title': {AppLanguage.lt: 'Ištrinti paskyrą?', AppLanguage.en: 'Delete account?'},
    'delete_confirm_text': {AppLanguage.lt: 'Tai negrįžtamai ištrins jūsų paskyrą ir visus duomenis.', AppLanguage.en: 'This will permanently delete your account and all data.'},
    'cancel': {AppLanguage.lt: 'Atšaukti', AppLanguage.en: 'Cancel'},
    'delete': {AppLanguage.lt: 'Ištrinti', AppLanguage.en: 'Delete'},
    'recent_login_required': {AppLanguage.lt: 'Prisijunkite iš naujo prieš trinant paskyrą.', AppLanguage.en: 'Please re-login before deleting the account.'},
    'version': {AppLanguage.lt: 'Versija', AppLanguage.en: 'Version'},

    // Theme options
    'theme_light': {AppLanguage.lt: 'Šviesi', AppLanguage.en: 'Light'},
    'theme_dark': {AppLanguage.lt: 'Tamsi', AppLanguage.en: 'Dark'},

    // Language options
    'lang_lt': {AppLanguage.lt: 'Lietuvių', AppLanguage.en: 'Lithuanian'},
    'lang_en': {AppLanguage.lt: 'Anglų', AppLanguage.en: 'English'},

    // Questionnaire
    'redo_questionnaire_route': {AppLanguage.lt: 'Perdaryti klausimyną', AppLanguage.en: 'Redo questionnaire'},
    // Habits
    'habits_title': {AppLanguage.lt: 'Įpročiai', AppLanguage.en: 'Habits'},
    'your_habits': {AppLanguage.lt: 'Tavo įpročiai', AppLanguage.en: 'Your habits'},
    'your_goals': {AppLanguage.lt: 'Tavo tikslai', AppLanguage.en: 'Your goals'},
    'delete_habit_title': {AppLanguage.lt: 'Ištrinti įprotį?', AppLanguage.en: 'Delete habit?'},
    'delete_habit_confirm': {AppLanguage.lt: 'Ar tikrai norite ištrinti', AppLanguage.en: 'Are you sure you want to delete'},
    'no': {AppLanguage.lt: 'Ne', AppLanguage.en: 'No'},
    'yes': {AppLanguage.lt: 'Taip', AppLanguage.en: 'Yes'},
    'delete_goal_title': {AppLanguage.lt: 'Ištrinti tikslą?', AppLanguage.en: 'Delete goal?'},
    'delete_goal_confirm': {AppLanguage.lt: 'Ar tikrai norite ištrinti', AppLanguage.en: 'Are you sure you want to delete'},
    'gained_xp': {AppLanguage.lt: 'Gavai +20 XP!', AppLanguage.en: 'You gained +20 XP!'},
    'select_hint': {AppLanguage.lt: 'Pasirinkti', AppLanguage.en: 'Choose'},
  };
}


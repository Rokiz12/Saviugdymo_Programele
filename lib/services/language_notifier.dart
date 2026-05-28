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
    'premium_activated_false': {AppLanguage.lt: 'Neaktyvi', AppLanguage.en: 'Not active'},
    'premium_activated_true': {AppLanguage.lt: 'Aktyvi', AppLanguage.en: 'Active'},

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
    // Goal editor
    'edit_goal': {AppLanguage.lt: 'Redaguoti tikslą', AppLanguage.en: 'Edit goal'},
    'new_goal': {AppLanguage.lt: 'Naujas tikslas', AppLanguage.en: 'New goal'},
    'title_label': {AppLanguage.lt: 'Pavadinimas', AppLanguage.en: 'Title'},
    'habit_label': {AppLanguage.lt: 'Įprotis', AppLanguage.en: 'Habit'},
    'goal_number_label': {AppLanguage.lt: 'Tikslas (skaičius)', AppLanguage.en: 'Goal (number)'},
    'period_label': {AppLanguage.lt: 'Laikotarpis', AppLanguage.en: 'Period'},
    'period_day': {AppLanguage.lt: 'Diena', AppLanguage.en: 'Day'},
    'period_week': {AppLanguage.lt: 'Savaitė', AppLanguage.en: 'Week'},
    'period_month': {AppLanguage.lt: 'Mėnuo', AppLanguage.en: 'Month'},
    'period_year': {AppLanguage.lt: 'Metai', AppLanguage.en: 'Year'},
    'period_custom': {AppLanguage.lt: 'Custom (dienomis)', AppLanguage.en: 'Custom (days)'},
    'custom_period_label': {AppLanguage.lt: 'Laikotarpis (dienomis)', AppLanguage.en: 'Period (days)'},
    'custom_period_hint': {AppLanguage.lt: 'pvz.: 10 (kas 10 dienų)', AppLanguage.en: 'e.g.: 10 (every 10 days)'},
    //'cancel': {AppLanguage.lt: 'Atšaukti', AppLanguage.en: 'Cancel'},
    'save': {AppLanguage.lt: 'Išsaugoti', AppLanguage.en: 'Save'},
    'add': {AppLanguage.lt: 'Pridėti', AppLanguage.en: 'Add'},
    'period_days': {AppLanguage.lt: 'Laikotarpis(dienomis)', AppLanguage.en: 'Period(days)'},
    //Habit editor
    'edit_habit': {AppLanguage.lt: 'Redaguoti įprotį', AppLanguage.en: 'Edit habit'},
    'new_habit': {AppLanguage.lt: 'Naujas įprotis', AppLanguage.en: 'New habit'},
    'icon_label': {AppLanguage.lt: 'Ikonėlė', AppLanguage.en: 'Icon'},
    //'name_label': {AppLanguage.lt: 'Pavadinimas', AppLanguage.en: 'Name'},
    'type_label': {AppLanguage.lt: 'Tipas', AppLanguage.en: 'Type'},
    'type_checkbox': {AppLanguage.lt: 'Pažyma (✔/✖)', AppLanguage.en: 'Checkbox (✔/✖)'},
    'type_number': {AppLanguage.lt: 'Skaičius', AppLanguage.en: 'Number'},
    'type_scale': {AppLanguage.lt: 'Skalė', AppLanguage.en: 'Scale'},
    'type_category': {AppLanguage.lt: 'Kategorija', AppLanguage.en: 'Category'},
    'type_steps': {AppLanguage.lt: 'Žingsniai 👟', AppLanguage.en: 'Steps 👟'},
    'options_label': {AppLanguage.lt: 'Parinktys (atskirti kableliais)', AppLanguage.en: 'Options (comma separated)'},
    'steps_goal_label': {AppLanguage.lt: 'Tikslas (žingsniai)', AppLanguage.en: 'Goal (steps)'},
    'steps_goal_hint': {AppLanguage.lt: 'pvz. 10000', AppLanguage.en: 'e.g. 10000'},
    'steps_auto_complete': {AppLanguage.lt: 'Pažymės kaip atliktą automatiškai, kai pasieksite tikslą.', AppLanguage.en: 'Will automatically mark as completed when you reach the goal.'},
    //'cancel': {AppLanguage.lt: 'Atšaukti', AppLanguage.en: 'Cancel'},
    //'save': {AppLanguage.lt: 'Išsaugoti', AppLanguage.en: 'Save'},
    //'add': {AppLanguage.lt: 'Pridėti', AppLanguage.en: 'Add'},
    'min': {AppLanguage.lt: 'Min', AppLanguage.en: 'Min'},
    'max': {AppLanguage.lt: 'Max', AppLanguage.en: 'Max'},
    'icon': {AppLanguage.lt: 'Ikonėlė', AppLanguage.en: 'Icon'},

    //statistics
    'statistics': {AppLanguage.lt: 'Statistika', AppLanguage.en: 'Statistics'},
    'habits': {AppLanguage.lt: 'Įpročiai', AppLanguage.en: 'Habits'},
    'mood': {AppLanguage.lt: 'Nuotaika', AppLanguage.en: 'Mood'},

    'mon_short': {AppLanguage.lt: 'Pr', AppLanguage.en: 'Mon'},
    'tue_short': {AppLanguage.lt: 'An', AppLanguage.en: 'Tue'},
    'wed_short': {AppLanguage.lt: 'Tr', AppLanguage.en: 'Wed'},
    'thu_short': {AppLanguage.lt: 'Kt', AppLanguage.en: 'Thu'},
    'fri_short': {AppLanguage.lt: 'Pn', AppLanguage.en: 'Fri'},
    'sat_short': {AppLanguage.lt: 'Št', AppLanguage.en: 'Sat'},
    'sun_short': {AppLanguage.lt: 'Sk', AppLanguage.en: 'Sun'},

    'mood_bad': {AppLanguage.lt: '😭 Blogai', AppLanguage.en: '😭 Bad'},
    'mood_poor': {AppLanguage.lt: '😢 Prastai', AppLanguage.en: '😢 Poor'},
    'mood_normal': {AppLanguage.lt: '😐 Normaliai', AppLanguage.en: '😐 Normal'},
    'mood_good': {AppLanguage.lt: '🙂 Gerai', AppLanguage.en: '🙂 Good'},
    'mood_great': {AppLanguage.lt: '😀 Puikiai', AppLanguage.en: '😀 Great'},

    'no_mood_data': {AppLanguage.lt: 'Nėra šio mėnesio nuotaikos duomenų', AppLanguage.en: 'No mood data for this month'},

    //'premium_title': {AppLanguage.lt: '66 dienų premium', AppLanguage.en: '66 days premium'},
    'premium_desc': {AppLanguage.lt: 'Neriboti įrašai, nuotraukos ir išsami statistika.', AppLanguage.en: 'Unlimited entries, photos and detailed statistics.'},
    'get': {AppLanguage.lt: 'Gauti', AppLanguage.en: 'Get'},

    //Avatar
    'user_not_found': {AppLanguage.lt: 'Vartotojas nerastas', AppLanguage.en: 'User not found'},
    'no_pet': {AppLanguage.lt: 'Nėra augintinio', AppLanguage.en: 'No Pet'},
    'common': {AppLanguage.lt: 'Įprastas', AppLanguage.en: 'Common'},

    'tap_to_hide': {AppLanguage.lt: 'Paspausk, kad paslėptum', AppLanguage.en: 'Tap to hide'},
    'tap_for_motivation': {AppLanguage.lt: 'Paspausk motyvacijai!', AppLanguage.en: 'Tap for motivation!'},

    'level': {AppLanguage.lt: 'Lygis', AppLanguage.en: 'Level'},

    'days_streak': {AppLanguage.lt: 'Dienų streakas', AppLanguage.en: 'Day streak'},
    'experience_points': {AppLanguage.lt: 'Patirties taškai', AppLanguage.en: 'Experience points'},

    'wardrobe': {AppLanguage.lt: 'Apranga', AppLanguage.en: 'Wardrobe'},

    //MINIGAMES
    'failed_load_pets': {AppLanguage.lt: 'Nepavyko užkrauti augintinių', AppLanguage.en: 'Failed to load pets'},
    'retry': {AppLanguage.lt: 'Bandyti dar kartą', AppLanguage.en: 'Retry'},
    //'days_streak': {AppLanguage.lt: 'Dienų streakas', AppLanguage.en: 'Day streak'},
    'xp': {AppLanguage.lt: 'Patirties taškai', AppLanguage.en: 'XP'},
    'equipped_success': {AppLanguage.lt: 'uždėtas!', AppLanguage.en: 'equipped!'},
    'failed_equip_pet': {AppLanguage.lt: 'Nepavyko uždėti augintinio', AppLanguage.en: 'Failed to equip pet'},
    'no_lore_available': {AppLanguage.lt: 'Nėra istorijos.', AppLanguage.en: 'No lore available.'},
    'lore': {AppLanguage.lt: 'Istorija', AppLanguage.en: 'Lore'},
    'lore_locked': {AppLanguage.lt: 'Istorija (užrakinta)', AppLanguage.en: 'Lore (Locked)'},
    'unlock_pet_lore': {AppLanguage.lt: 'Atrakink šį augintinį, kad pamatytum jo istoriją...', AppLanguage.en: 'Unlock this pet to reveal its secrets...'},
    'equipping': {AppLanguage.lt: 'Uždedama', AppLanguage.en: 'Equipping'},
    'equip': {AppLanguage.lt: 'Uždėti', AppLanguage.en: 'Equip'},
    'equipped': {AppLanguage.lt: 'Uždėtas', AppLanguage.en: 'Equipped'},
    //'level': {AppLanguage.lt: 'Lygis', AppLanguage.en: 'Level'},

    //diary
    // Diary
    'diary_new': {AppLanguage.lt: 'Naujas', AppLanguage.en: 'New'},
    'diary_calendar': {AppLanguage.lt: 'Kalendorius', AppLanguage.en: 'Calendar'},
    'diary_memories': {AppLanguage.lt: 'Prisiminimai', AppLanguage.en: 'Memories'},
    'diary_m': {AppLanguage.lt: 'Kaip jautiesi šiandien?', AppLanguage.en: 'How do you feel today?'},
    'diary_diary_entry': {AppLanguage.lt: 'Laisvas dienoraštis', AppLanguage.en: 'Diary entry'},
    'write_here': {AppLanguage.lt: 'Rašyk čia...', AppLanguage.en: 'Write here...'},
    'diary_add_photo': {AppLanguage.lt: 'Pridėti nuotrauką(neprivaloma)', AppLanguage.en: 'Add photo(optional)'},
    'save_entry': {AppLanguage.lt: 'Išsaugoti įrašą', AppLanguage.en: 'Save entry'},
    'entry_saved': {AppLanguage.lt: 'Įrašas išsaugotas!', AppLanguage.en: 'Entry saved!'},
    'diary_press_to_add': {AppLanguage.lt: 'Paspauskite, kad pridėtumėte', AppLanguage.en: 'Press to add'},
    'pick_gallery': {AppLanguage.lt: 'Galerija', AppLanguage.en: 'Gallery'},
    'take_photo': {AppLanguage.lt: 'Kamera', AppLanguage.en: 'Camera'},
    'pick_mood': {AppLanguage.lt: 'Pasirink nuotaiką', AppLanguage.en: 'Select mood'},

    'no_memories': {AppLanguage.lt: 'Nėra prisiminimų', AppLanguage.en: 'No memories'},

    'diary_mood_bad': {AppLanguage.lt: 'Blogai', AppLanguage.en: 'Bad'},
    'diary_mood_poor': {AppLanguage.lt: 'Prastai', AppLanguage.en: 'Poor'},
    'diary_mood_normal': {AppLanguage.lt: 'Normaliai', AppLanguage.en: 'Normal'},
    'diary_mood_good': {AppLanguage.lt: 'Gerai', AppLanguage.en: 'Good'},
    'diary_mood_great': {AppLanguage.lt: 'Puikiai', AppLanguage.en: 'Great'},


    'premium_required': {AppLanguage.lt: 'Reikia Premium', AppLanguage.en: 'Premium required'},
    'premium_photo_limit': {AppLanguage.lt: 'Pasiektas nuotraukų limitas', AppLanguage.en: 'Photo limit reached'},
    'premium_entry_limit': {AppLanguage.lt: 'Pasiektas įrašų limitas', AppLanguage.en: 'Entry limit reached'},

    //'gained_xp': {AppLanguage.lt: 'Gavai XP!', AppLanguage.en: 'You gained XP!'},
    'close': {AppLanguage.lt: 'Uždaryti', AppLanguage.en: 'Close'},
    'no_entries_day': {AppLanguage.lt: 'Nėra įrašų šiai dienai', AppLanguage.en: 'No entries for this day'},
    'diary_add_new_entry': {AppLanguage.lt: 'Pridėti naują įrašą', AppLanguage.en: 'Add new entry'},
    //'save_entry': {AppLanguage.lt: 'Išsaugoti įrašą', AppLanguage.en: 'Save entry'},

  };


}


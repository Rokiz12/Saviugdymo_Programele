import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:before_after/before_after.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pvp/services/sound_service.dart';
import '../data/repositories/diary_repository.dart';
import '../data/models/diary_entry_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/diary_question_repository.dart';
import '../data/models/diary_question_model.dart';
import '../services/reward_service.dart';
import '../services/reward_notifier.dart';
import '../theme/app_theme.dart';
import '../services/language_notifier.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  DateTime _weekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  int _entriesThisWeek(List<DiaryEntryModel> entries) {
    final start = _weekStart();
    return entries.where((e) => !e.createdAt.isBefore(start)).length;
  }

  int _photosThisWeek(List<DiaryEntryModel> entries) {
    final start = _weekStart();
    return entries
        .where((e) =>
    !e.createdAt.isBefore(start) &&
        e.imageUrl != null &&
        e.imageUrl!.isNotEmpty)
        .length;
  }

  void _showUpgradeDialog(String message) {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.background2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(lang.t('premium_feature_title'),
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.textColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: TextStyle(color: colors.textColor)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.intenseColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.t('premium_benefits_title'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.textColor)),
                  const SizedBox(height: 6),
                  Text(lang.t('premium_benefit_unlimited_entries'),
                      style: TextStyle(color: colors.textColor)),
                  Text(lang.t('premium_benefit_unlimited_photos'),
                      style: TextStyle(color: colors.textColor)),
                  Text(lang.t('premium_benefit_stats'),
                      style: TextStyle(color: colors.textColor)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel'),
                style: TextStyle(color: colors.appBarUnpickedColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.intenseColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(lang.t('get'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  final DiaryRepository _repository = DiaryRepository();
  final DiaryQuestionRepository _questionRepository = DiaryQuestionRepository();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  bool _isSelectionMode = false;
  Set<String> _selectedForDeletion = {};

  int _memoriesViewIndex = 0;
  String? _selectedCategoryView;

  List<String> _categories = [];
  String _selectedUploadCategory = '';

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<DiaryEntryModel>> _entriesByDate = {};

  String selectedMood = "";
  List<DiaryQuestionModel> _currentQuestions = [];
  bool _questionsLoaded = false;

  final textControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<String> _moods = [
    'diary_mood_great',
    'diary_mood_good',
    'diary_mood_normal',
    'diary_mood_poor',
    'diary_mood_bad'
  ];
  final List<String> _moodEmojis = ['😀', '🙂', '😐', '😢', '😭'];

  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadQuestions();
    _loadUserPremiumStatus();
  }

  Future<void> _loadCategories() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('diary_settings')
          .doc('categories')
          .get();

      if (doc.exists && doc.data() != null && doc.data()!['list'] != null) {
        setState(() {
          _categories = List<String>.from(doc.data()!['list']);
          _selectedUploadCategory = _categories.isNotEmpty ? _categories.first : '';
        });
      } else {
        setState(() {
          _categories = ['Svorio metimas', 'Odos būklė', 'Kambario tvarka', 'Kūryba'];
          _selectedUploadCategory = _categories.first;
        });
        _saveCategories();
      }
    } catch (e) {
      debugPrint("Klaida užkraunant kategorijas: $e");
    }
  }

  Future<void> _saveCategories() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('diary_settings')
          .doc('categories')
          .set({'list': _categories});
    } catch (e) {
      debugPrint("Klaida saugant kategorijas: $e");
    }
  }

  void _showAddCategoryDialog() {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.background2,
          title: Text(lang.t('new_category'),
              style: TextStyle(color: colors.textColor)),
          content: TextField(
            controller: catController,
            style: TextStyle(color: colors.textColor),
            decoration: InputDecoration(
              hintText: lang.t('category_hint'),
              hintStyle: TextStyle(color: colors.appBarUnpickedColor),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('cancel'),
                  style: TextStyle(color: colors.textColor)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = catController.text.trim();
                if (text.isNotEmpty && !_categories.contains(text)) {
                  setState(() {
                    _categories.add(text);
                    if (_categories.length == 1) {
                      _selectedUploadCategory = text;
                    }
                  });
                  _saveCategories();
                  Navigator.pop(context);
                } else if (_categories.contains(text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lang.t('category_already_exists'))),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.intenseColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(lang.t('add')),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryDialog(String category) {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.background2,
          title: Text(lang.t('delete_category_confirm'),
              style: TextStyle(color: colors.textColor)),
          content: Text(
              lang.t('delete_category_text').replaceAll('{category}', category),
              style: TextStyle(color: colors.textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('cancel'),
                  style: TextStyle(color: colors.textColor)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _categories.remove(category);
                  if (_selectedUploadCategory == category) {
                    _selectedUploadCategory =
                    _categories.isNotEmpty ? _categories.first : '';
                  }
                });
                _saveCategories();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang
                        .t('category_deleted')
                        .replaceAll('{category}', category)),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(lang.t('delete')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUserPremiumStatus() async {
    final user = await UserRepository().getUser(_userId);
    if (user != null && mounted) {
      setState(() => _isPremium = user.premium);
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _questionRepository
          .getOneRandomFromEachCategory(['highlight', 'reflect', 'gratitude']);
      setState(() {
        _currentQuestions = questions;
        _questionsLoaded = true;
      });
    } catch (e) {
      debugPrint("Error loading questions: $e");
      setState(() {
        _questionsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    for (var c in textControllers) c.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final lang = context.read<LanguageNotifier>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(lang
                  .t('failed_open_camera_gallery')
                  .replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();
    if (!_isPremium) {
      final allEntries = _entriesByDate.values.expand((e) => e).toList();
      if (_photosThisWeek(allEntries) >= 3) {
        _showUpgradeDialog(lang
            .t('photo_limit_week_msg')
            .replaceAll('{this_week}', '${_photosThisWeek(allEntries)}')
            .replaceAll('{limit}', '3'));
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final lang = context.read<LanguageNotifier>();
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.appBarUnpickedColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: colors.textColor),
                title: Text(lang.t('pick_gallery'),
                    style: TextStyle(color: colors.textColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: colors.textColor),
                title: Text(lang.t('take_photo'),
                    style: TextStyle(color: colors.textColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveEntry() async {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();

    if (!_isPremium) {
      final allEntries = _entriesByDate.values.expand((e) => e).toList();
      if (_entriesThisWeek(allEntries) >= 2) {
        _showUpgradeDialog(lang
            .t('entry_limit_week_msg')
            .replaceAll('{this_week}', '${_entriesThisWeek(allEntries)}')
            .replaceAll('{limit}', '2'));
        return;
      }
    }

    if (selectedMood.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('pick_mood'))),
      );
      return;
    }

    if (_moods.indexOf(selectedMood) <= 1) {
      SoundService.playHappyDiary();
    } else {
      SoundService.playSadDiary();
    }

    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: colors.intenseColor)),
    );

    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}';
    String? uploadedImageUrl;

    try {
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(_userId)
            .child('diary_images')
            .child('$id.jpg');

        final task = await ref.putFile(_selectedImage!);
        uploadedImageUrl = await task.ref.getDownloadURL();
      }

      final preview = textControllers[0].text.isNotEmpty
          ? textControllers[0].text
          : (textControllers[3].text.isNotEmpty
          ? textControllers[3].text
          : lang.t('empty_entry'));

      String? finalCategory;
      if (_selectedImage != null && _categories.isNotEmpty) {
        finalCategory = _categories.contains(_selectedUploadCategory)
            ? _selectedUploadCategory
            : _categories.first;
      }

      final idx = _moods.indexOf(selectedMood);
      final moodLabel =
      (idx >= 0 && idx < _moods.length) ? lang.t(_moods[idx]) : selectedMood;
      final moodEmoji =
      (idx >= 0 && idx < _moodEmojis.length) ? _moodEmojis[idx] : '';

      await _repository.addEntry(
        _userId,
        DiaryEntryModel(
          id: id,
          createdAt: now,
          mood: '$moodEmoji $moodLabel',
          highlight: textControllers[0].text,
          better: textControllers[1].text,
          gratitude: textControllers[2].text,
          diaryText: textControllers[3].text,
          preview: preview.length > 50
              ? '${preview.substring(0, 47)}...'
              : preview,
          imageUrl: uploadedImageUrl,
          category: finalCategory,
        ),
      );

      if (!mounted) return;
      navigator.pop();

      setState(() {
        selectedMood = "";
        _selectedImage = null;
      });
      for (var c in textControllers) c.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(lang.t('entry_saved')),
              backgroundColor: Colors.green),
        );
      }

      _loadQuestions();

      final userRepo = UserRepository();
      final (
      granted: gotXp,
      oldLevel: oldLevel,
      newLevel: newLevel,
      ) = await userRepo.tryGiveDiaryXp(_userId, 20);

      if (gotXp) {
        RewardService().checkLevelUp(
            userId: _userId,
            oldLevel: oldLevel,
            newLevel: newLevel,
            notifier: context.read<RewardNotifier>());
      }
      if (gotXp && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(lang.t('gained_xp'),
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        DefaultTabController.of(context)?.animateTo(1);
      });
    } catch (e) {
      if (mounted) navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(lang
                  .t('error_with_details')
                  .replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  void _groupEntries(List<DiaryEntryModel> entries) {
    _entriesByDate = {};
    for (var e in entries) {
      DateTime date =
      DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      (_entriesByDate[date] ??= []).add(e);
    }
  }

  List<DateTime> _getDaysInMonth() {
    DateTime first =
    DateTime(_currentMonth.year, _currentMonth.month, 1);
    DateTime last =
    DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    int leading = first.weekday - 1;

    var days = List.generate(leading, (i) => DateTime(first.year, first.month, -i))
        .reversed
        .toList();
    days.addAll(List.generate(
        last.day, (i) => DateTime(first.year, first.month, i + 1)));
    return days;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final lang = context.watch<LanguageNotifier>();
    try {
      return DateFormat.yMMMd(lang.locale).format(date);
    } catch (_) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: CustomAppBar(
          title: lang.t('nav_diary'),
          bottom: TabBar(
            indicatorColor: colors.intenseColor,
            labelColor: colors.textColor,
            unselectedLabelColor: colors.appBarUnpickedColor,
            tabs: [
              Tab(icon: const Icon(Icons.add), text: lang.t('diary_new')),
              Tab(
                  icon: const Icon(Icons.calendar_month),
                  text: lang.t('diary_calendar')),
              Tab(
                  icon: const Icon(Icons.photo_library),
                  text: lang.t('diary_memories')),
            ],
          ),
        ),
        body: StreamBuilder<List<DiaryEntryModel>>(
          stream: _repository.streamEntries(_userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: colors.intenseColor));
            }

            final entries = snapshot.data ?? [];
            _groupEntries(entries);

            return TabBarView(
              children: [
                _buildNewEntryTab(),
                _buildCalendarTab(),
                _buildMemoriesTab(entries),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewEntryTab() {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();

    if (!_questionsLoaded) {
      return Center(
          child: CircularProgressIndicator(color: colors.intenseColor));
    }

    if (_currentQuestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: colors.appBarUnpickedColor),
              const SizedBox(height: 16),
              Text(
                lang.t('questions_unavailable'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: colors.textColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: Text(lang.t('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.intenseColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(lang.t('diary_m'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) => _moodBtn(i)),
          ),
          const SizedBox(height: 32),

          for (int i = 0; i < _currentQuestions.length; i++)
            _buildField(_currentQuestions[i].question, i,
                maxLines: _currentQuestions[i].maxLines),

          _buildField(lang.t('diary_diary_entry'), 3, maxLines: 4),

          const SizedBox(height: 16),

          Text(
            lang.t('diary_add_photo'),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.textColor),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: colors.background2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.background, width: 1.5),
              ),
              child: _selectedImage != null
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child:
                    Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      size: 48, color: colors.appBarUnpickedColor),
                  const SizedBox(height: 12),
                  Text(lang.t('diary_press_to_add'),
                      style: TextStyle(
                          color: colors.appBarUnpickedColor,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),

          if (_selectedImage != null) ...[
            const SizedBox(height: 20),
            if (_categories.isNotEmpty) ...[
              Text(lang.t('select_category'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: colors.textColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedUploadCategory)
                    ? _selectedUploadCategory
                    : _categories.first,
                dropdownColor: colors.background2,
                style: TextStyle(color: colors.textColor, fontSize: 16),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: colors.background2,
                ),
                items: _categories
                    .map((cat) =>
                    DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null)
                    setState(() => _selectedUploadCategory = val);
                },
              ),
            ] else ...[
              Text(
                lang.t('no_categories_message'),
                style: TextStyle(
                    color: colors.appBarUnpickedColor,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: _saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.intenseColor,
              foregroundColor: Colors.black,
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(lang.t('save_entry'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();
    return Column(
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month - 1)),
                icon: Icon(Icons.chevron_left, color: colors.textColor),
              ),
              Text(
                DateFormat.yMMMM(lang.locale).format(_currentMonth),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor),
              ),
              IconButton(
                onPressed: () => setState(() => _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month + 1)),
                icon: Icon(Icons.chevron_right, color: colors.textColor),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: Center(child: Text(lang.t('mon_short'), style: TextStyle(fontWeight: FontWeight.bold, color: colors.appBarUnpickedColor)))),
              Expanded(child: Center(child: Text(lang.t('tue_short'), style: TextStyle(fontWeight: FontWeight.bold, color: colors.appBarUnpickedColor)))),
              Expanded(child: Center(child: Text(lang.t('wed_short'), style: TextStyle(fontWeight: FontWeight.bold, color: colors.appBarUnpickedColor)))),
              Expanded(child: Center(child: Text(lang.t('thu_short'), style: TextStyle(fontWeight: FontWeight.bold, color: colors.appBarUnpickedColor)))),
              Expanded(child: Center(child: Text(lang.t('fri_short'), style: TextStyle(fontWeight: FontWeight.bold, color: colors.appBarUnpickedColor)))),
              Expanded(child: Center(child: Text(lang.t('sat_short'), style: TextStyle(fontWeight: FontWeight.bold, color: colors.appBarUnpickedColor)))),
              Expanded(child: Center(child: Text(lang.t('sun_short'), style: TextStyle(fontWeight: FontWeight.bold, color: colors.appBarUnpickedColor)))),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4),
              itemCount: _getDaysInMonth().length,
              itemBuilder: (context, index) {
                final day = _getDaysInMonth()[index];
                final isCurrent = day.month == _currentMonth.month;
                final hasEntry = _entriesByDate.containsKey(
                    DateTime(day.year, day.month, day.day));
                final isSelected = _selectedDay != null &&
                    day.year == _selectedDay!.year &&
                    day.month == _selectedDay!.month &&
                    day.day == _selectedDay!.day;

                return GestureDetector(
                  onTap: isCurrent ? () => _onDayTap(day) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colors.intenseColor
                          : (isCurrent && hasEntry
                          ? colors.primary
                          : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontWeight: isSelected || hasEntry
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? (isSelected
                              ? Colors.black
                              : colors.textColor)
                              : colors.appBarUnpickedColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () =>
                DefaultTabController.of(context).animateTo(0),
            icon: const Icon(Icons.add),
            label: Text(lang.t('diary_add_new_entry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.intenseColor,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSelectedImages(List<DiaryEntryModel> memories) async {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: colors.intenseColor)),
    );

    try {
      for (String id in _selectedForDeletion) {
        final entry = memories.firstWhere((e) => e.id == id);

        if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
          try {
            await FirebaseStorage.instance
                .refFromURL(entry.imageUrl!)
                .delete();
          } catch (e) {
            debugPrint("Nepavyko ištrinti failo iš Storage: $e");
          }
        }

        final updatedEntry = DiaryEntryModel(
          id: entry.id,
          createdAt: entry.createdAt,
          mood: entry.mood,
          highlight: entry.highlight,
          better: entry.better,
          gratitude: entry.gratitude,
          diaryText: entry.diaryText,
          preview: entry.preview,
          imageUrl: null,
          category: entry.category,
        );

        await _repository.addEntry(_userId, updatedEntry);
      }

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        _isSelectionMode = false;
        _selectedForDeletion.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang.t('photos_deleted_success')),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang
                .t('photos_delete_error')
                .replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildMemoriesTab(List<DiaryEntryModel> allEntries) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();
    final memories = allEntries
        .where((e) => e.imageUrl != null && e.imageUrl!.isNotEmpty)
        .toList();
    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                    value: 0,
                    label: Text(lang.t('memories_categories')),
                    icon: const Icon(Icons.folder)),
                ButtonSegment(
                    value: 1,
                    label: Text(lang.t('memories_all')),
                    icon: const Icon(Icons.photo_library)),
              ],
              selected: {_memoriesViewIndex},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _memoriesViewIndex = newSelection.first;
                  _selectedCategoryView = null;
                  _isSelectionMode = false;
                  _selectedForDeletion.clear();
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) => states.contains(WidgetState.selected)
                      ? colors.intenseColor
                      : colors.background2,
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) => states.contains(WidgetState.selected)
                      ? Colors.black
                      : colors.textColor,
                ),
                side: WidgetStateProperty.all(
                    BorderSide(color: colors.background, width: 1)),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ),
        ),

        if (_isSelectionMode)
          Container(
            color: colors.primary,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang
                      .t('n_selected')
                      .replaceAll('{count}', '${_selectedForDeletion.length}'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colors.textColor),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        if (_selectedForDeletion.isNotEmpty) {
                          _deleteSelectedImages(memories);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textColor),
                      onPressed: () => setState(() {
                        _isSelectionMode = false;
                        _selectedForDeletion.clear();
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),

        Expanded(
          child: _memoriesViewIndex == 0
              ? _buildCategoriesView(memories)
              : _buildAllPhotosView(memories),
        ),
      ],
    );
  }

  Widget _buildCategoriesView(List<DiaryEntryModel> memories) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();

    if (_selectedCategoryView == null) {
      return Stack(
        children: [
          if (_categories.isEmpty)
            Center(
              child: Text(lang.t('create_first_category'),
                  style: TextStyle(color: colors.appBarUnpickedColor)),
            )
          else
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final catMemories =
                memories.where((e) => e.category == cat).toList();

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryView = cat),
                  onLongPress: () => _showDeleteCategoryDialog(cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.background2,
                      borderRadius: BorderRadius.circular(16),
                      border:
                      Border.all(color: colors.background, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_special,
                            size: 48, color: colors.intenseColor),
                        const SizedBox(height: 12),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            cat,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colors.textColor),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.t('photos_count_short').replaceAll(
                              '{count}', '${catMemories.length}'),
                          style: TextStyle(
                              color: colors.appBarUnpickedColor,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: colors.intenseColor,
              foregroundColor: Colors.black,
              onPressed: _showAddCategoryDialog,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    } else {
      final categoryMemories =
      memories.where((e) => e.category == _selectedCategoryView).toList();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.textColor),
                  onPressed: () => setState(() {
                    _selectedCategoryView = null;
                    _isSelectionMode = false;
                    _selectedForDeletion.clear();
                  }),
                ),
                Expanded(
                  child: Text(
                    _selectedCategoryView!,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (!_isSelectionMode)
            _buildComparisonForCategory(categoryMemories),
          Expanded(
            child: categoryMemories.isEmpty
                ? Center(
                child: Text(lang.t('no_photos_in_category'),
                    style:
                    TextStyle(color: colors.appBarUnpickedColor)))
                : _buildPhotoGrid(categoryMemories),
          ),
        ],
      );
    }
  }

  Widget _buildComparisonForCategory(List<DiaryEntryModel> categoryMemories) {
    final lang = context.read<LanguageNotifier>();
    if (categoryMemories.length < 2) return const SizedBox.shrink();

    final today = DateTime.now();
    DiaryEntryModel? memoryFromToday;
    DiaryEntryModel? pastMemory;
    String singleTitle = "";
    String comparisonTitle = "";

    try {
      memoryFromToday = categoryMemories.firstWhere((e) =>
      e.createdAt.year == today.year &&
          e.createdAt.month == today.month &&
          e.createdAt.day == today.day);
    } catch (_) {}

    try {
      pastMemory = categoryMemories.firstWhere((e) =>
      e.createdAt.year == today.year - 1 &&
          e.createdAt.month == today.month &&
          e.createdAt.day == today.day);
      singleTitle = lang.t('comparison_year_ago_title');
      comparisonTitle = lang.t('comparison_year_progress');
    } catch (_) {}

    if (pastMemory == null) {
      final oneMonthAgo =
      DateTime(today.year, today.month - 1, today.day);
      try {
        pastMemory = categoryMemories.firstWhere((e) =>
        e.createdAt.year == oneMonthAgo.year &&
            e.createdAt.month == oneMonthAgo.month &&
            e.createdAt.day == oneMonthAgo.day);
        singleTitle = lang.t('comparison_month_ago_title');
        comparisonTitle = lang.t('comparison_month_progress');
      } catch (_) {}
    }

    if (memoryFromToday != null &&
        pastMemory != null &&
        memoryFromToday.id != pastMemory.id) {
      return _buildComparisonPreviewCard(
          pastMemory, memoryFromToday, comparisonTitle);
    } else if (pastMemory != null) {
      return _buildSpecialMemoryCard(pastMemory, singleTitle);
    }

    return const SizedBox.shrink();
  }

  Widget _buildAllPhotosView(List<DiaryEntryModel> memories) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();
    if (memories.isEmpty) {
      return Center(
          child: Text(lang.t('no_photos_yet'),
              style: TextStyle(color: colors.appBarUnpickedColor)));
    }
    return _buildPhotoGrid(memories);
  }

  Widget _buildPhotoGrid(List<DiaryEntryModel> photos) {
    final colors = context.colors;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.8),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final entry = photos[index];
        final isSelected = _selectedForDeletion.contains(entry.id);

        return GestureDetector(
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedForDeletion.add(entry.id);
            });
          },
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedForDeletion.remove(entry.id);
                  if (_selectedForDeletion.isEmpty)
                    _isSelectionMode = false;
                } else {
                  _selectedForDeletion.add(entry.id);
                }
              });
            } else {
              _showEntryDialog(entry);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: entry.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colors.background2,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: colors.intenseColor, strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.error, color: colors.appBarUnpickedColor),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.black.withOpacity(0.6),
                    child: Text(
                      _formatDate(context, entry.createdAt),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (_isSelectionMode)
                  Container(
                    color: isSelected
                        ? Colors.black.withOpacity(0.6)
                        : Colors.black.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: isSelected
                        ? Icon(Icons.check_circle,
                        color: colors.intenseColor, size: 36)
                        : const Icon(Icons.circle_outlined,
                        color: Colors.white70, size: 36),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonPreviewCard(DiaryEntryModel beforeEntry,
      DiaryEntryModel afterEntry, String title) {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FullScreenComparisonPage(
            beforeEntry: beforeEntry,
            afterEntry: afterEntry,
            title: title,
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
          image: DecorationImage(
            image: CachedNetworkImageProvider(afterEntry.imageUrl!),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), BlendMode.darken),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.compare_arrows,
                  color: colors.intenseColor, size: 40),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(lang.t('press_to_compare'),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialMemoryCard(DiaryEntryModel entry, String title) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => _showEntryDialog(entry),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
          image: DecorationImage(
            image: CachedNetworkImageProvider(entry.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Colors.black87, Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.center,
            ),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.intenseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history,
                        size: 16, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDayTap(DateTime day) {
    final lang = context.read<LanguageNotifier>();
    setState(() => _selectedDay = day);
    final entries =
    _entriesByDate[DateTime(day.year, day.month, day.day)];

    if (entries == null || entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${lang.t('no_entries_day')} ${_formatDate(context, day)}')),
      );
    } else if (entries.length == 1) {
      _showEntryDialog(entries.first);
    } else {
      _showEntriesList(entries);
    }
  }

  void _showEntryDialog(DiaryEntryModel e) {
    final colors = context.colors;
    final lang = context.read<LanguageNotifier>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.background2,
        title: Text(_formatDate(context, e.createdAt),
            style: TextStyle(color: colors.textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                Text(e.mood, style: TextStyle(color: colors.textColor)),
              ),
              if (e.highlight.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text("✨ ${e.highlight}",
                    style: TextStyle(color: colors.textColor)),
              ],
              if (e.diaryText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text("📖 ${e.diaryText}",
                    style: TextStyle(color: colors.textColor)),
              ],
              if (e.imageUrl != null && e.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: e.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                            color: colors.intenseColor)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('close'),
                style: TextStyle(color: colors.textColor)),
          ),
        ],
      ),
    );
  }

  void _showEntriesList(List<DiaryEntryModel> entries) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.appBarUnpickedColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Text(
              _formatDate(context, entries.first.createdAt),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor),
            ),
            const SizedBox(height: 16),
            ...entries.map((e) => ListTile(
              leading: Text(e.mood.split(' ')[0],
                  style: const TextStyle(fontSize: 24)),
              title: Text(
                  '${e.createdAt.hour}:${e.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: colors.textColor)),
              subtitle: Text(e.preview,
                  maxLines: 1,
                  style:
                  TextStyle(color: colors.appBarUnpickedColor)),
              onTap: () {
                Navigator.pop(context);
                _showEntryDialog(e);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _moodBtn(int i) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();
    final isSelected = selectedMood == _moods[i];
    return GestureDetector(
      onTap: () => setState(() => selectedMood = _moods[i]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? colors.intenseColor : colors.background2,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                  color: colors.textColor.withOpacity(0.2), width: 1)
                  : Border.all(color: colors.background, width: 1.5),
            ),
            child: Text(_moodEmojis[i],
                style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(
            lang.t(_moods[i]),
            style: TextStyle(
                fontSize: 11,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
                color: colors.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String hint, int index, {int maxLines = 2}) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hint.startsWith('diary_') ? lang.t(hint) : hint,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textColor,
                fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: textControllers[index],
            maxLines: maxLines,
            style: TextStyle(color: colors.textColor),
            decoration: InputDecoration(
              hintText: lang.t('write_here'),
              hintStyle: TextStyle(color: colors.appBarUnpickedColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colors.background2,
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenComparisonPage extends StatefulWidget {
  final DiaryEntryModel beforeEntry;
  final DiaryEntryModel afterEntry;
  final String title;

  const FullScreenComparisonPage({
    super.key,
    required this.beforeEntry,
    required this.afterEntry,
    required this.title,
  });

  @override
  State<FullScreenComparisonPage> createState() =>
      _FullScreenComparisonPageState();
}

class _FullScreenComparisonPageState
    extends State<FullScreenComparisonPage> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lang = context.watch<LanguageNotifier>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: BeforeAfter(
            value: _sliderValue,
            before: CachedNetworkImage(
                imageUrl: widget.afterEntry.imageUrl!, fit: BoxFit.cover),
            after: CachedNetworkImage(
                imageUrl: widget.beforeEntry.imageUrl!, fit: BoxFit.cover),
            trackColor: colors.intenseColor,
            thumbColor: colors.intenseColor,
            onValueChanged: (value) {
              setState(() => _sliderValue = value);
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.t('before'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(lang.t('after_today'),
                  style: TextStyle(
                      color: colors.intenseColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
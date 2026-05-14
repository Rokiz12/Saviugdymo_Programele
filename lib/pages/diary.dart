import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:before_after/before_after.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Counts diary entries created this week
  int _entriesThisWeek(List<DiaryEntryModel> entries) {
    final start = _weekStart();
    return entries.where((e) => !e.createdAt.isBefore(start)).length;
  }

  /// Counts entries with photos created this week
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('⭐', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Premium funkcija',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow[300]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premium privalumai:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('✅ Neriboti dienoraščio įrašai'),
                  Text('✅ Neriboti nuotraukų prisegimas'),
                  Text('✅ Visi statistikos įrankiai'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vėliau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: navigate to your upgrade/paywall page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Gauti Premium',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  final DiaryRepository _repository = DiaryRepository();
  final DiaryQuestionRepository _questionRepository = DiaryQuestionRepository();
  
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // Memories Tab Variables
  bool _isSelectionMode = false;
  Set<String> _selectedForDeletion = {};
  

  int _memoriesViewIndex = 0; 
  String? _selectedCategoryView;

  // categories for uploading
  final List<String> _categories = ['test 1', 'test 2', 'test 3', 'test 4'];
  String _selectedUploadCategory = 'test 1';

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<DiaryEntryModel>> _entriesByDate = {};

  String selectedMood = "";
  List<DiaryQuestionModel> _currentQuestions =[];
  bool _questionsLoaded = false;
  
  final textControllers = [
    TextEditingController(), 
    TextEditingController(), 
    TextEditingController(), 
    TextEditingController(), 
  ];

  final List<String> _weekDays = ['P', 'A', 'T', 'K', 'P', 'Š', 'S'];
  final List<String> _moods = ['Puikiai', 'Gerai', 'Normaliai', 'Prastai', 'Blogai'];
  final List<String> _moodEmojis = ['😀', '🙂', '😐', '😢', '😭'];

  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _selectedUploadCategory = _categories.first;
    _loadQuestions();
    _loadUserPremiumStatus();
  }

  Future<void> _loadUserPremiumStatus() async {
    final user = await UserRepository().getUser(_userId);
    if (user != null && mounted) {
      setState(() => _isPremium = user.premium);
    }
  }



  Future<void> _loadQuestions() async {
    try {
      final questions = await _questionRepository.getOneRandomFromEachCategory(['highlight', 'reflect', 'gratitude']);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nepavyko atidaryti kameros/galerijos: $e")),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    // --- PREMIUM GATE ---
    if (!_isPremium) {
      final allEntries = _entriesByDate.values.expand((e) => e).toList();
      if (_photosThisWeek(allEntries) >= 3) {
        _showUpgradeDialog(
          'Nemokamoje versijoje galima prisegti tik 3 nuotraukas per savaitę.\n\n'
              'Ši savaitė: ${_photosThisWeek(allEntries)} / 3 nuotraukos.',
        );
        return;
      }
    }
    // --- END GATE ---

    showModalBottomSheet(  // rest of existing method unchanged
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black),
                title: const Text('Pasirinkti iš galerijos'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.black),
                title: const Text('Daryti naują nuotrauką'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveEntry() async {

    if (!_isPremium) {
      final allEntries = _entriesByDate.values.expand((e) => e).toList();
      if (_entriesThisWeek(allEntries) >= 2) {
        _showUpgradeDialog(
          'Nemokamoje versijoje galima pridėti tik 2 įrašus per savaitę.\n\n'
              'Ši savaitė: ${_entriesThisWeek(allEntries)} / 2 įrašai.',
        );
        return;
      }
    }

    if (selectedMood.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pasirink nuotaiką!")),
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
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.yellow)),
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
              : "Tuščias įrašas");

      await _repository.addEntry(
        _userId,
        DiaryEntryModel(
          id: id,
          createdAt: now,
          mood: '${_moodEmojis[_moods.indexOf(selectedMood)]} $selectedMood',
          highlight: textControllers[0].text,
          better: textControllers[1].text,
          gratitude: textControllers[2].text,
          diaryText: textControllers[3].text,
          preview: preview.length > 50 ? '${preview.substring(0, 47)}...' : preview,
          imageUrl: uploadedImageUrl,
          category: _selectedImage != null ? _selectedUploadCategory : null, 
        ),
      );

      if (!mounted) return;

      navigator.pop();

      setState(() {
        selectedMood = "";
        _selectedImage = null;
      });
      for (var c in textControllers) {
        c.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Įrašas išsaugotas!"), backgroundColor: Colors.green),
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
        RewardService().checkLevelUp(userId: _userId, oldLevel: oldLevel, newLevel: newLevel, notifier: context.read<RewardNotifier>());
      }
      if (gotXp && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gavai +20 XP!", style: TextStyle(fontWeight: FontWeight.bold))),
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
          SnackBar(content: Text("Klaida: $e")),
        );
      }
    }
  }

  void _groupEntries(List<DiaryEntryModel> entries) {
    _entriesByDate = {};
    for (var e in entries) {
      DateTime date = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      (_entriesByDate[date] ??=[]).add(e);
    }
  }

  List<DateTime> _getDaysInMonth() {
    DateTime first = DateTime(_currentMonth.year, _currentMonth.month, 1);
    DateTime last = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    int leading = first.weekday - 1;

    var days = List.generate(leading, (i) => DateTime(first.year, first.month, -i)).reversed.toList();
    days.addAll(List.generate(last.day, (i) => DateTime(first.year, first.month, i + 1)));
    return days;
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _getMonthName(int m) => ['Sausis', 'Vasaris', 'Kovas', 'Balandis', 'Gegužė', 'Birželis',
        'Liepa', 'Rugpjūtis', 'Rugsėjis', 'Spalis', 'Lapkritis', 'Gruodis'][m - 1];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Dienoraštis',
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: "Naujas"),
              Tab(icon: Icon(Icons.calendar_month), text: "Kalendorius"),
              Tab(icon: Icon(Icons.photo_library), text: "Prisiminimai"),
            ],
          ),
        ),
        body: StreamBuilder<List<DiaryEntryModel>>(
          stream: _repository.streamEntries(_userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = snapshot.data ??[];
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
    if (!_questionsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQuestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Atsiprašome, klausimai nėra prieinami",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text("Bandyti dar kartą"),
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
        children:[
          const Text("Kaip jautiesi?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) => _moodBtn(i)),
          ),
          const SizedBox(height: 24),
          
          ...[
            for (int i = 0; i < _currentQuestions.length; i++)
              _buildField(
                _currentQuestions[i].question,
                i,
                maxLines: _currentQuestions[i].maxLines,
              ),
          ],
          
          _buildField("Laisvas dienoraštis", 3, maxLines: 4),
          
          const SizedBox(height: 24),
          
          const Text(
            "Prisegti nuotrauką (neprivaloma)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showImagePickerOptions, 
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _selectedImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children:[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:[
                        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Paspauskite, kad pridėtumėte", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
          ),

          if (_selectedImage != null) ...[
            const SizedBox(height: 16),
            const Text("Pasirinkite kategoriją:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedUploadCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedUploadCategory = val);
              },
            ),
          ],

          const SizedBox(height: 32), 

          ElevatedButton(

            onPressed: _saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Išsaugoti įrašą", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children:[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              IconButton(onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)), icon: const Icon(Icons.chevron_left)),
              Text('${_currentMonth.year} ${_getMonthName(_currentMonth.month)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)), icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold))))).toList(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
              itemCount: _getDaysInMonth().length,
              itemBuilder: (context, index) {
                final day = _getDaysInMonth()[index];
                final isCurrent = day.month == _currentMonth.month;
                final hasEntry = _entriesByDate.containsKey(DateTime(day.year, day.month, day.day));
                final isSelected = _selectedDay != null &&
                    day.year == _selectedDay!.year && day.month == _selectedDay!.month && day.day == _selectedDay!.day;

                return GestureDetector(
                  onTap: isCurrent ? () => _onDayTap(day) : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.yellow : (isCurrent && hasEntry ? Colors.yellow[100] : null),
                    ),
                    child: Center(child: Text(
                      day.day.toString(),
                      style: TextStyle(color: isCurrent ? Colors.black : Colors.grey[300]),
                    )),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => DefaultTabController.of(context).animateTo(0),
            icon: const Icon(Icons.add),
            label: const Text("Pridėti naują įrašą"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSelectedImages(List<DiaryEntryModel> memories) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.yellow)),
    );

    try {
      for (String id in _selectedForDeletion) {
        final entry = memories.firstWhere((e) => e.id == id);
        
        if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(entry.imageUrl!).delete();
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
        const SnackBar(content: Text("Nuotraukos sėkmingai ištrintos!"), backgroundColor: Colors.green),
      );
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Klaida trinant nuotraukas: $e"), backgroundColor: Colors.red),
      );
    }
  }


  Widget _buildMemoriesTab(List<DiaryEntryModel> allEntries) {
    final memories = allEntries.where((e) => e.imageUrl != null && e.imageUrl!.isNotEmpty).toList();
    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text("Kategorijos"), icon: Icon(Icons.folder)),
              ButtonSegment(value: 1, label: Text("Visos"), icon: Icon(Icons.photo_library)),
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
                (states) => states.contains(WidgetState.selected) ? Colors.yellow : Colors.white,
              ),
              foregroundColor: WidgetStateProperty.all(Colors.black),
            ),
          ),
        ),

 
        if (_isSelectionMode)
          Container(
            color: Colors.yellow[300],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                Text(
                  "${_selectedForDeletion.length} pasirinkta", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                Row(
                  children:[
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (_selectedForDeletion.isNotEmpty) {
                          _deleteSelectedImages(memories);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
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
    
    if (_selectedCategoryView == null) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          crossAxisSpacing: 16, 
          mainAxisSpacing: 16, 
          childAspectRatio: 1.0,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final catMemories = memories.where((e) => e.category == cat).toList();

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryView = cat;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  const Icon(Icons.folder_special, size: 50, color: Colors.yellow),
                  const SizedBox(height: 8),
                  Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("${catMemories.length} nuotr.", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          );
        },
      );
    } 
    
    
    else {
      final categoryMemories = memories.where((e) => e.category == _selectedCategoryView).toList();
      
      return Column(
        children:[
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children:[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() {
                    _selectedCategoryView = null;
                    _isSelectionMode = false;
                    _selectedForDeletion.clear();
                  }),
                ),
                Text(
                  _selectedCategoryView!, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),

          
          if (!_isSelectionMode)
             _buildComparisonForCategory(categoryMemories),

          Expanded(
            child: categoryMemories.isEmpty
                ? const Center(child: Text("Šioje kategorijoje nėra nuotraukų."))
                : _buildPhotoGrid(categoryMemories),
          ),
        ],
      );
    }
  }

  
  Widget _buildComparisonForCategory(List<DiaryEntryModel> categoryMemories) {
    if (categoryMemories.length < 2) return const SizedBox.shrink();

    final today = DateTime.now();
    DiaryEntryModel? memoryFromToday;
    DiaryEntryModel? pastMemory;
    String singleTitle = "";
    String comparisonTitle = "";

    try { memoryFromToday = categoryMemories.firstWhere((e) => e.createdAt.year == today.year && e.createdAt.month == today.month && e.createdAt.day == today.day); } catch (_) {}
    
    try {
      pastMemory = categoryMemories.firstWhere((e) => e.createdAt.year == today.year - 1 && e.createdAt.month == today.month && e.createdAt.day == today.day);
      singleTitle = "Prieš metus šioje kategorijoje..."; comparisonTitle = "1 Metų Progresas!";
    } catch (_) {}

    if (pastMemory == null) {
      final oneMonthAgo = DateTime(today.year, today.month - 1, today.day);
      try {
        pastMemory = categoryMemories.firstWhere((e) => e.createdAt.year == oneMonthAgo.year && e.createdAt.month == oneMonthAgo.month && e.createdAt.day == oneMonthAgo.day);
        singleTitle = "Prieš mėnesį šioje kategorijoje..."; comparisonTitle = "1 Mėnesio Progresas!";
      } catch (_) {}
    }

    if (memoryFromToday != null && pastMemory != null && memoryFromToday.id != pastMemory.id) {
      return _buildComparisonPreviewCard(pastMemory, memoryFromToday, comparisonTitle);
    } else if (pastMemory != null) {
      return _buildSpecialMemoryCard(pastMemory, singleTitle);
    }

    return const SizedBox.shrink();
  }

  
  Widget _buildAllPhotosView(List<DiaryEntryModel> memories) {
    if (memories.isEmpty) {
      return const Center(child: Text("Dar nėra jokių nuotraukų."));
    }
    return _buildPhotoGrid(memories);
  }

 
  Widget _buildPhotoGrid(List<DiaryEntryModel> photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 0.8,
      ),
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
                  if (_selectedForDeletion.isEmpty) _isSelectionMode = false;
                } else {
                  _selectedForDeletion.add(entry.id);
                }
              });
            } else {
              _showEntryDialog(entry);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children:[
                
                CachedNetworkImage(
                  imageUrl: entry.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(color: Colors.yellow, strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.black54,
                    child: Text(_formatDate(entry.createdAt), style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center),
                  ),
                ),

                if (_isSelectionMode)
                  Container(
                    color: isSelected ? Colors.black54 : Colors.black12,
                    alignment: Alignment.center,
                    child: isSelected 
                        ? const Icon(Icons.check_circle, color: Colors.yellow, size: 36)
                        : const Icon(Icons.circle_outlined, color: Colors.white70, size: 36),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonPreviewCard(DiaryEntryModel beforeEntry, DiaryEntryModel afterEntry, String title) {
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
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
          image: DecorationImage(
            image: CachedNetworkImageProvider(afterEntry.imageUrl!), 
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              const Icon(Icons.compare_arrows, color: Colors.yellow, size: 40),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Paspauskite, kad palygintumėte!",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialMemoryCard(DiaryEntryModel entry, String title) {
    return GestureDetector(
      onTap: () => _showEntryDialog(entry),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
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
            )
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    const Icon(Icons.history, size: 16, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
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
    setState(() => _selectedDay = day);
    final entries = _entriesByDate[DateTime(day.year, day.month, day.day)];

    if (entries == null || entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nėra įrašų ${_formatDate(day)}")),
      );
    } else if (entries.length == 1) {
      _showEntryDialog(entries.first);
    } else {
      _showEntriesList(entries);
    }
  }

  void _showEntryDialog(DiaryEntryModel e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_formatDate(e.createdAt)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8), 
                color: Colors.yellow[100], 
                child: Text(e.mood)
              ),
              if (e.highlight.isNotEmpty) ...[
                const SizedBox(height: 8), 
                Text("✨ ${e.highlight}")
              ],
              if (e.diaryText.isNotEmpty) ...[
                const SizedBox(height: 8), 
                Text("📖 ${e.diaryText}")
              ],
              
              if (e.imageUrl != null && e.imageUrl!.isNotEmpty) ...[
                 const SizedBox(height: 16),
                 ClipRRect(
                   borderRadius: BorderRadius.circular(12),
                   child: CachedNetworkImage(
                     imageUrl: e.imageUrl!,
                     fit: BoxFit.contain,
                     placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                   ),
                 ),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Uždaryti")
          )
        ],
      ),
    );
  }

  void _showEntriesList(List<DiaryEntryModel> entries) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            Text(_formatDate(entries.first.createdAt), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...entries.map((e) => ListTile(
              leading: Text(e.mood.split(' ')[0]),
              title: Text('${e.createdAt.hour}:${e.createdAt.minute}'),
              subtitle: Text(e.preview, maxLines: 1),
              onTap: () { Navigator.pop(context); _showEntryDialog(e); },
            )),
          ],
        ),
      ),
    );
  }

  Widget _moodBtn(int i) {
    return GestureDetector(
      onTap: () => setState(() => selectedMood = _moods[i]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selectedMood == _moods[i] ? Colors.yellow[200] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: selectedMood == _moods[i] ? Border.all(color: Colors.yellow[800]!, width: 2) : null,
            ),
            child: Text(_moodEmojis[i], style: const TextStyle(fontSize: 24)),
          ),
          Text(_moods[i], style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildField(String hint, int index, {int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hint, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: textControllers[index],
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: "Rašyk čia...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
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
  State<FullScreenComparisonPage> createState() => _FullScreenComparisonPageState();
}

class _FullScreenComparisonPageState extends State<FullScreenComparisonPage> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
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
            before: CachedNetworkImage(imageUrl: widget.afterEntry.imageUrl!, fit: BoxFit.cover),
            after: CachedNetworkImage(imageUrl: widget.beforeEntry.imageUrl!, fit: BoxFit.cover), 
            trackColor: Colors.yellow,
            thumbColor: Colors.yellow,
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
            children: const[
              Text("PRIEŠ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text("PO (ŠIANDIEN)", style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
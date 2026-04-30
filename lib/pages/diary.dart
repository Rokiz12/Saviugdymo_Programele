import 'package:flutter/material.dart';
import 'package:pvp/services/sound_service.dart';
import '../data/repositories/diary_repository.dart';
import '../data/models/diary_entry_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/diary_question_repository.dart';
import '../data/models/diary_question_model.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final DiaryRepository _repository = DiaryRepository();
  final DiaryQuestionRepository _questionRepository = DiaryQuestionRepository();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // Calendar
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<DiaryEntryModel>> _entriesByDate = {};

  // Form
  String selectedMood = "";
  List<DiaryQuestionModel> _currentQuestions = [];
  late List<TextEditingController> textControllers;
  bool _questionsLoaded = false;

  final List<String> _weekDays = ['P', 'A', 'T', 'K', 'P', 'Š', 'S'];
  final List<String> _moods = ['Puikiai', 'Gerai', 'Normaliai', 'Prastai', 'Blogai'];
  final List<String> _moodEmojis = ['😀', '🙂', '😐', '😢', '😭'];

  @override
  void initState() {
    super.initState();
    textControllers = List.generate(3, (_) => TextEditingController());
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _questionRepository.getOneRandomFromEachCategory(
        ['highlight', 'reflect', 'gratitude'],
      );
      setState(() {
        _currentQuestions = questions;
        _questionsLoaded = true;
      });
    } catch (e) {
      print("Error loading questions: $e");
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

  void _groupEntries(List<DiaryEntryModel> entries) {
    _entriesByDate = {};
    for (var e in entries) {
      DateTime date = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      (_entriesByDate[date] ??= []).add(e);
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

  Future<void> _saveEntry() async {
    final now = DateTime.now();

    if (selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pasirink nuotaiką!")),
      );
      return;
    }

    if(_moods.indexOf(selectedMood)<=1) {
      SoundService.playHappyDiary();
    } else {
      SoundService.playSadDiary();
    }

    final preview = textControllers[0].text.isNotEmpty
        ? textControllers[0].text
        : (textControllers[2].text.isNotEmpty ? textControllers[2].text : "Tuščias įrašas");

    await _repository.addEntry(_userId, DiaryEntryModel(
      id: '${now.millisecondsSinceEpoch}',
      createdAt: now,
      mood: '${_moodEmojis[_moods.indexOf(selectedMood)]} $selectedMood',
      highlight: textControllers[0].text,
      better: textControllers[1].text,
      gratitude: textControllers[2].text,
      diaryText: '',
      preview: preview.length > 50 ? '${preview.substring(0, 47)}...' : preview,
    ));

    setState(() => selectedMood = "");
    for (var c in textControllers) c.clear();
    _loadQuestions(); // Load new random questions

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Įrašas išsaugotas!"), backgroundColor: Colors.green),
      );
    }

    final userRepo = UserRepository();

    final gotXp = await userRepo.tryGiveDiaryXp(_userId, 10);

    if (gotXp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gavai +10 XP!")),
      );
    }
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Dienoraštis',
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: "Naujas"),
              Tab(icon: Icon(Icons.calendar_month), text: "Kalendorius"),
            ],
          ),
        ),
        body: StreamBuilder<List<DiaryEntryModel>>(
          stream: _repository.streamEntries(_userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            _groupEntries(snapshot.data ?? []);

            return TabBarView(
              children: [
                _buildNewEntryTab(),
                _buildCalendarTab(),
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
            children: [
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
        children: [
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Išsaugoti įrašą"),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(8), color: Colors.yellow[100], child: Text(e.mood)),
              if (e.highlight.isNotEmpty) ...[const SizedBox(height: 8), Text("✨ ${e.highlight}")],
              if (e.diaryText.isNotEmpty) ...[const SizedBox(height: 8), Text("📖 ${e.diaryText}")],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Uždaryti"))],
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
          children: [
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

  String _getMonthName(int m) =>
      ['Sausis', 'Vasaris', 'Kovas', 'Balandis', 'Gegužė', 'Birželis',
        'Liepa', 'Rugpjūtis', 'Rugsėjis', 'Spalis', 'Lapkritis', 'Gruodis'][m - 1];
}
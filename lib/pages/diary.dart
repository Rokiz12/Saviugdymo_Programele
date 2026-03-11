import 'package:flutter/material.dart';
import 'dart:math';
import '../data/repositories/diary_repository.dart';
import '../data/models/diary_entry_model.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DiaryRepository _repository = DiaryRepository();

  // Laikinas useris
  final String _userId = "test_user_123";

  // Mood tracker kintamieji
  String selectedMood = "";
  final highlightController = TextEditingController();
  final betterController = TextEditingController();
  final gratitudeController = TextEditingController();

  // Dienorasti inputas
  final freeJournalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    highlightController.dispose();
    betterController.dispose();
    gratitudeController.dispose();
    freeJournalController.dispose();
    super.dispose();
  }

  // id kurimas
  String _generateId() {
    final now = DateTime.now();
    final random = Random().nextInt(10000);
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}_$random';
  }

  // Irasas
  Widget _buildNewEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kaip šiandien jautiesi?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _moodButton("😀", "Puikiai"),
              _moodButton("🙂", "Gerai"),
              _moodButton("😐", "Normaliai"),
              _moodButton("😢", "Prastai"),
              _moodButton("😭", "Blogai"),
            ],
          ),

          const SizedBox(height: 24),

          _questionField("Kas šiandien nutiko gero?", highlightController),
          _questionField("Kas galėjo būti geriau?", betterController),
          _questionField("Už ką tu šiandien dėkingas?", gratitudeController),

          const SizedBox(height: 16),

          Divider(thickness: 2, color: Colors.grey[300]),

          const SizedBox(height: 16),

          _freeJournalField(),

          const SizedBox(height: 24),

          Center(
            child: ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Išsaugoti įrašą",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Irasu perziura
  Widget _buildViewEntriesTab() {
    return StreamBuilder<List<DiaryEntryModel>>(
      stream: _repository.streamEntries(_userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Klaida: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return const Center(
            child: Text(
              "Dar nėra įrašų",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.mood,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                title: Text(
                  _formatDate(entry.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  entry.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showEntryDetails(entry),
              ),
            );
          },
        );
      },
    );
  }

  // Pagalbiniai widgetai

  Widget _moodButton(String emoji, String label) {
    bool isSelected = selectedMood == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = label;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.yellow[200] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: Colors.yellow[800]!, width: 2) : null,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _questionField(String question, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Rašyk čia...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _freeJournalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Laisvas dienoraštis",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: freeJournalController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Rašyk čia...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // funkcijos

  void _saveEntry() async {
    if (selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pasirink nuotaiką!")),
      );
      return;
    }

    final now = DateTime.now();

    // Sukuriam ID iš DateTime
    final String id = _generateId();

    // Sukuriam naują įrašą naudojant modelį
    final newEntry = DiaryEntryModel(
      id: id,
      createdAt: now,
      mood: _getMoodEmoji(selectedMood) + " " + selectedMood,
      highlight: highlightController.text,
      better: betterController.text,
      gratitude: gratitudeController.text,
      diaryText: freeJournalController.text,
      preview: DiaryEntryModel.generatePreview(
        highlightController.text,
        freeJournalController.text,
      ),
    );

    // Saugom į Firestore
    await _repository.addEntry(_userId, newEntry);

    // Išvalom laukus
    setState(() {
      selectedMood = "";
    });
    highlightController.clear();
    betterController.clear();
    gratitudeController.clear();
    freeJournalController.clear();

    // Rodom patvirtinimą
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Įrašas išsaugotas!"),
        backgroundColor: Colors.green,
      ),
    );

    // Perjungiam į įrašų peržiūrą
    _tabController.animateTo(1);
  }

  String _getMoodEmoji(String mood) {
    switch(mood) {
      case "Puikiai": return "😀";
      case "Gerai": return "🙂";
      case "Normaliai": return "😐";
      case "Prastai": return "😢";
      case "Blogai": return "😭";
      default: return "😐";
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return "Šiandien";
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (entryDate == yesterday) {
      return "Vakar";
    }

    const months = [
      'Sausio', 'Vasario', 'Kovo', 'Balandžio', 'Gegužės', 'Birželio',
      'Liepos', 'Rugpjūčio', 'Rugsėjo', 'Spalio', 'Lapkričio', 'Gruodžio'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _showEntryDetails(DiaryEntryModel entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatDate(entry.createdAt)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mood
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(entry.mood),
              ),
              const SizedBox(height: 16),

              // Mood tracker answers
              if (entry.highlight.isNotEmpty) ...[
                const Text("✨ Kas gero:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry.highlight),
                const SizedBox(height: 8),
              ],

              if (entry.better.isNotEmpty) ...[
                const Text("📝 Galėjo būti geriau:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry.better),
                const SizedBox(height: 8),
              ],

              if (entry.gratitude.isNotEmpty) ...[
                const Text("🙏 Dėkingas:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry.gratitude),
                const SizedBox(height: 8),
              ],

              // Free journal
              if (entry.diaryText.isNotEmpty) ...[
                const Divider(),
                const Text("📖 Dienoraštis:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry.diaryText),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Uždaryti"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dienoraštis',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: "Naujas"),
            Tab(icon: Icon(Icons.list), text: "Įrašai"),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [
          _buildNewEntryTab(),
          _buildViewEntriesTab(),
        ],
      ),
    );
  }
}
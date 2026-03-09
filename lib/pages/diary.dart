import 'package:flutter/material.dart';
import 'dart:math';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mood tracker kintamieji
  String selectedMood = "";
  final highlightController = TextEditingController();
  final betterController = TextEditingController();
  final gratitudeController = TextEditingController();

  // Laisvo dienoraščio kintamasis
  final freeJournalController = TextEditingController();

  // TESTINIAI DUOMENYS (vėliau pakeisi į duomenų bazę)
  List<Map<String, dynamic>> diaryEntries = [
    {
      'date': 'Vasaris 24, 2026',
      'mood': '😀 Puikiai',
      'preview': 'Pasivaikščiojimas parke. Oras puikus, jaučiausi energingas.',
      'highlight': 'Pasivaikščiojimas parke',
      'better': 'Galėjau anksčiau keltis',
      'gratitude': 'Saulėta diena',
      'freeText': 'Šiandien buvo nuostabi diena. Oras puikus, jaučiausi energingas.',
    },
    {
      'date': 'Vasaris 23, 2026',
      'mood': '🙂 Gerai',
      'preview': 'Kava su draugu. Malonu prisiminti senus laikus.',
      'highlight': 'Kava su draugu',
      'better': 'Daug darbo',
      'gratitude': 'Draugystė',
      'freeText': 'Susitikau su senu draugu. Malonu prisiminti senus laikus.',
    },
    {
      'date': 'Vasaris 22, 2026',
      'mood': '😐 Normaliai',
      'preview': 'Skaičiau knygą. Ramu.',
      'highlight': 'Nauja knyga',
      'better': 'Galėjau daugiau perskaityti',
      'gratitude': 'Ramybė',
      'freeText': 'Skaičiau knygą. Ramu.',
    },
  ];

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

  // ============ NAUJAS ĮRAŠAS ============
  Widget _buildNewEntryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood selection
          Text(
            "Kaip šiandien jautiesi?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

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

          SizedBox(height: 24),

          // Mood tracker questions
          _questionField("Kas šiandien nutiko gero?", highlightController),
          _questionField("Kas galėjo būti geriau?", betterController),
          _questionField("Už ką tu šiandien dėkingas?", gratitudeController),

          SizedBox(height: 16),

          // Separator
          Divider(thickness: 2, color: Colors.grey[300]),

          SizedBox(height: 16),

          // Free journal
          _freeJournalField(),

          SizedBox(height: 24),

          // Save button
          Center(
            child: ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Išsaugoti įrašą",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============ ĮRAŠŲ PERŽIŪRA ============
  Widget _buildViewEntriesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: diaryEntries.length,
      itemBuilder: (context, index) {
        final entry = diaryEntries[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry['mood'],
                style: TextStyle(fontSize: 14),
              ),
            ),
            title: Text(
              entry['date'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              entry['preview'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showEntryDetails(entry),
          ),
        );
      },
    );
  }

  // ============ HELPER WIDGETS ============

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
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.yellow[200] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: Colors.yellow[800]!, width: 2) : null,
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 28),
            ),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        SizedBox(height: 6),
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
        SizedBox(height: 16),
      ],
    );
  }

  Widget _freeJournalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Laisvas dienoraštis",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: freeJournalController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Rašyk ką nori...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _saveEntry() {
    if (selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pasirink nuotaiką!")),
      );
      return;
    }

    // Sukuriam naują įrašą
    Map<String, dynamic> newEntry = {
      'date': 'Vasaris ${DateTime.now().day}, 2026',
      'mood': _getMoodEmoji(selectedMood) + " " + selectedMood,
      'preview': highlightController.text.isNotEmpty
          ? highlightController.text
          : (freeJournalController.text.isNotEmpty
          ? freeJournalController.text.substring(0, min(50, freeJournalController.text.length))
          : "Tuščias įrašas"),
      'highlight': highlightController.text,
      'better': betterController.text,
      'gratitude': gratitudeController.text,
      'freeText': freeJournalController.text,
    };

    setState(() {
      diaryEntries.insert(0, newEntry);
    });

    // Išvalom laukus
    selectedMood = "";
    highlightController.clear();
    betterController.clear();
    gratitudeController.clear();
    freeJournalController.clear();

    // Rodom patvirtinimą
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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

  void _showEntryDetails(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry['date']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mood
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(entry['mood']),
              ),
              SizedBox(height: 16),

              // Mood tracker answers
              if (entry['highlight'].isNotEmpty) ...[
                Text("✨ Kas gero:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry['highlight']),
                SizedBox(height: 8),
              ],

              if (entry['better'].isNotEmpty) ...[
                Text("📝 Galėjo būti geriau:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry['better']),
                SizedBox(height: 8),
              ],

              if (entry['gratitude'].isNotEmpty) ...[
                Text("🙏 Dėkingas:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry['gratitude']),
                SizedBox(height: 8),
              ],

              // Free journal
              if (entry['freeText'].isNotEmpty) ...[
                Divider(),
                Text("📖 Dienoraštis:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry['freeText']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Uždaryti"),
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
      body: IndexedStack(  // ← VISIŠKAI JOKIO SCROLL
        index: _tabController.index,
        children: [
          _buildNewEntryTab(),
          _buildViewEntriesTab(),
        ],
      ),
    );
  }
}